# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/admin/chronicles", type: :request do
  let(:admin_user) { FactoryBot.create(:user, role: "admin") }
  let(:regular_user) { FactoryBot.create(:user, role: "user") }
  let(:team) { FactoryBot.create(:team) }
  let(:valid_attributes) do
    {
      name: "Admin Curated Andalusia Roadtrip",
      notice: "A curated chronicle narrative across the southern coast of Spain.",
      start_date: Date.current,
      end_date: Date.current + 7.days,
      visibility: "internal",
      team_id: team.id,
    }
  end
  let(:invalid_attributes) do
    {
      name: nil,
      notice: "too short",
      start_date: nil,
      team_id: nil,
    }
  end

  describe "when user is authenticated as an admin" do
    before { sign_in(admin_user) }

    describe "GET /admin/chronicles" do
      it "renders a successful response displaying the first picture and omitting other entries" do
        chronicle = Chronicle.create!(valid_attributes)
        picture = FactoryBot.create(:picture, team: team, name: "Admin Audit Picture")
        thought = FactoryBot.create(:thought, team: team, text: "Internal admin note")
        FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: picture, position: 1)
        FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: thought, position: 2)

        get admin_chronicles_url
        expect(response).to be_successful
        expect(response.body).to include("Admin Audit Picture")
        expect(response.body).not_to include("Internal admin note")
      end
    end

    describe "GET /admin/chronicles/:id" do
      it "renders a successful response displaying all entries" do
        chronicle = Chronicle.create!(valid_attributes)
        picture = FactoryBot.create(:picture, team: team, name: "Admin Audit Picture")
        thought = FactoryBot.create(:thought, team: team, text: "Internal admin note")
        FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: picture, position: 1)
        FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: thought, position: 2)

        get admin_chronicle_url(chronicle)
        expect(response).to be_successful
        expect(response.body).to include("Admin Audit Picture")
        expect(response.body).to include("Internal admin note")
      end

      it "displays all pictures when multiple pictures are attached to a chronicle (regression test)" do
        chronicle = Chronicle.create!(valid_attributes)
        pic1 = FactoryBot.create(:picture, team: team, name: "Admin Audit Picture 1")
        pic2 = FactoryBot.create(:picture, team: team, name: "Admin Audit Picture 2")
        FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: pic1, position: 1)
        FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: pic2, position: 2)

        get admin_chronicle_url(chronicle)
        expect(response).to be_successful
        expect(response.body).to include("Admin Audit Picture 1")
        expect(response.body).to include("Admin Audit Picture 2")
        expect(response.body.scan(/<article[^>]+id="picture_/).count).to eq(2)
      end
    end

    describe "GET /admin/chronicles/new" do
      it "renders a successful response" do
        get new_admin_chronicle_url
        expect(response).to be_successful
      end

      it "renders picture options with valid representation preview URLs and thumbnail images (regression test)" do
        FactoryBot.create(:picture, team: team, name: "Admin Audit Landscape")
        get new_admin_chronicle_url
        expect(response).to be_successful
        expect(response.body).to include("data-thumb-url=\"/rails/active_storage/representations/")
        expect(response.body).to include("Admin Audit Landscape")
      end
    end

    describe "GET /admin/chronicles/:id/edit" do
      it "renders a successful response" do
        chronicle = Chronicle.create!(valid_attributes)
        get edit_admin_chronicle_url(chronicle)
        expect(response).to be_successful
      end

      it "renders picture options with valid representation preview URLs and thumbnail images (regression test)" do
        chronicle = Chronicle.create!(valid_attributes)
        FactoryBot.create(:picture, team: team, name: "Admin Audit Landscape")
        get edit_admin_chronicle_url(chronicle)
        expect(response).to be_successful
        expect(response.body).to include("data-thumb-url=\"/rails/active_storage/representations/")
        expect(response.body).to include("Admin Audit Landscape")
      end

      it "renders edit form with attached entries, edit links and remove checkboxes (regression test)",
        aggregate_failures: true do
        chronicle = Chronicle.create!(valid_attributes)
        attached_pic1 = FactoryBot.create(:picture, team: team, name: "Admin Attached Pic 1")
        attached_pic2 = FactoryBot.create(:picture, team: team, name: "Admin Attached Pic 2")
        entry1 = FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: attached_pic1, position: 1)
        entry2 = FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: attached_pic2, position: 2)

        get edit_admin_chronicle_url(chronicle)
        expect(response).to be_successful
        expect(response.body).to include("Attached Entries")
        expect(response.body).to include("Admin Attached Pic 1")
        expect(response.body).to include("Admin Attached Pic 2")
        expect(response.body).to include(edit_admin_picture_path(attached_pic1))
        expect(response.body).to include(edit_admin_picture_path(attached_pic2))
        expect(response.body).to include("chronicle[entries_attributes]")
        expect(response.body).to include(ActionView::RecordIdentifier.dom_id(entry1))
        expect(response.body).to include(ActionView::RecordIdentifier.dom_id(entry2))
      end
    end

    describe "POST /admin/chronicles" do
      context "with valid parameters" do
        it "creates a new Chronicle and emits a RecordEvent marked as done_by_admin" do
          expect {
            post admin_chronicles_url, params: { chronicle: valid_attributes }
          }.to change { Chronicle.count }.by(1).and change { RecordEvent.count }.by(1)

          event = RecordEvent.last
          expect(event.name).to eq("created")
          expect(event.done_by_admin).to be true
          expect(event.team_id).to eq("admin")
          expect(event.user_id).to eq(admin_user.id)
        end

        it "redirects to the created chronicle" do
          post admin_chronicles_url, params: { chronicle: valid_attributes }
          expect(response).to redirect_to(admin_chronicle_url(Chronicle.first))
        end

        it "attaches an existing picture via picture_id param" do
          picture = FactoryBot.create(:picture, team: team)

          expect {
            post admin_chronicles_url, params: {
              chronicle: valid_attributes.merge(picture_id: picture.id),
            }
          }.to change { Chronicle.count }.by(1).and change { ChronicleEntry.count }.by(1)

          expect(Chronicle.first.pictures).to include(picture)
        end

        it "attaches Location, Thought, and Weblink on create" do
          loc = FactoryBot.create(:location, team: team)
          thot = FactoryBot.create(:thought, team: team)
          link = FactoryBot.create(:weblink, team: team)

          expect {
            post admin_chronicles_url, params: {
              chronicle: valid_attributes.merge(
                location_id: loc.id,
                thought_id: thot.id,
                weblink_id: link.id
              ),
            }
          }.to change { Chronicle.count }.by(1).and change { ChronicleEntry.count }.by(3)

          chronicle = Chronicle.first
          expect(chronicle.locations).to include(loc)
          expect(chronicle.thoughts).to include(thot)
          expect(chronicle.weblinks).to include(link)
        end
      end

      context "with invalid parameters" do
        it "does not create a new Chronicle" do
          expect {
            post admin_chronicles_url, params: { chronicle: invalid_attributes }
          }.to change { Chronicle.count }.by(0)
        end

        it "renders a response with 422 status" do
          post admin_chronicles_url, params: { chronicle: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    describe "PATCH /admin/chronicles/:id" do
      let!(:chronicle) { Chronicle.create!(valid_attributes) }

      context "with valid parameters" do
        it "updates the chronicle and attaches a picture when picture_id is provided" do
          picture = FactoryBot.create(:picture, team: team)

          expect {
            patch admin_chronicle_url(chronicle), params: {
              chronicle: { name: "Admin Renamed Chronicle", picture_id: picture.id },
            }
          }.to change { chronicle.entries.count }.by(1)

          expect(chronicle.reload.pictures).to include(picture)
        end

        it "attaches Location, Thought, and Weblink during update" do
          loc = FactoryBot.create(:location, team: team)

          expect {
            patch admin_chronicle_url(chronicle), params: {
              chronicle: {
                location_id: loc.id,
                thought_text: "Admin curated insight",
                weblink_name: "Admin Resource",
                weblink_url: "https://adminresource.example.com",
              },
            }
          }.to change { Thought.count }.by(1)
            .and change { Weblink.count }.by(1)
            .and change { chronicle.entries.count }.by(3)

          expect(chronicle.reload.locations).to include(loc)
          expect(chronicle.thoughts.pluck(:text)).to include("Admin curated insight")
          expect(chronicle.weblinks.pluck(:name)).to include("Admin Resource")
        end

        it "cascades visibility changes to attached entries when updated by admin" do
          picture = FactoryBot.create(:picture, team: team, visibility: "internal")
          FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: picture)

          patch admin_chronicle_url(chronicle), params: { chronicle: { visibility: "published" } }

          expect(response).to redirect_to(admin_chronicle_url(chronicle))
          expect(chronicle.reload.visibility).to eq("published")
          expect(picture.reload.visibility).to eq("published")
        end

        it "removes an attached picture entry via _destroy nested attribute (regression test)" do
          pic1 = FactoryBot.create(:picture, team: team, name: "Admin Keep Picture")
          pic2 = FactoryBot.create(:picture, team: team, name: "Admin Remove Picture")
          entry1 = FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: pic1, position: 1)
          entry2 = FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: pic2, position: 2)

          expect {
            patch admin_chronicle_url(chronicle), params: {
              chronicle: {
                entries_attributes: {
                  "0" => { id: entry1.id, _destroy: "0" },
                  "1" => { id: entry2.id, _destroy: "1" },
                },
              },
            }
          }.to change { chronicle.entries.count }.by(-1)

          expect(chronicle.reload.pictures).to eq([pic1])
          expect(Picture.exists?(pic2.id)).to be true
        end

        it "redirects to the chronicle" do
          patch admin_chronicle_url(chronicle), params: { chronicle: { name: "Admin Renamed Chronicle" } }
          expect(response).to redirect_to(admin_chronicle_url(chronicle))
        end
      end

      context "with invalid parameters" do
        it "renders a response with 422 status" do
          patch admin_chronicle_url(chronicle), params: { chronicle: { name: nil } }
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    describe "DELETE /admin/chronicles/:id" do
      let!(:chronicle) { Chronicle.create!(valid_attributes) }

      it "destroys the chronicle and emits a deleted RecordEvent" do
        expect {
          delete admin_chronicle_url(chronicle)
        }.to change { Chronicle.count }.by(-1).and change { RecordEvent.count }.by(1)

        event = RecordEvent.last
        expect(event.name).to eq("deleted")
        expect(event.done_by_admin).to be true
      end

      it "redirects to the chronicles list" do
        delete admin_chronicle_url(chronicle)
        expect(response).to redirect_to(admin_chronicles_url)
      end
    end
  end

  describe "when user is unauthenticated or not an admin" do
    it "returns 404 Not Found for non-admin" do
      sign_in(regular_user)
      get admin_chronicles_url
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 Not Found for guest" do
      get admin_chronicles_url
      expect(response).to have_http_status(:not_found)
    end
  end
end
