# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/current_team/chronicles", type: :request do
  let!(:member) { Member.create!(team: team, user: user, roles: Array(roles.sample)) }

  let(:user) { FactoryBot.create(:user) }
  let(:team) { FactoryBot.create(:team) }
  let(:roles) { %i[owner manager editor] }

  let(:valid_attributes) do
    {
      team: team,
      name: "Roadtrip through Andalusia",
      notice: "A detailed chronicle of our roadtrip across the southern coast of Spain.",
      start_date: Date.current,
      end_date: Date.current + 7.days,
      visibility: "internal",
    }
  end

  let(:invalid_attributes) do
    {
      name: nil,
      notice: "too short",
      start_date: nil,
    }
  end

  before do
    sign_in(user)
    switch_current_team(team)
  end

  describe "GET /index" do
    let!(:chronicle) { Chronicle.create!(valid_attributes) }

    context "when no current_team has been selected" do
      before { go_solo(team) }

      it "forbids access and redirects to root path" do
        get current_team_chronicles_url
        expect(response).to redirect_to(root_url)
      end
    end

    context "when current_team is selected" do
      let!(:thought) { FactoryBot.create(:thought, team: team, text: "Secret campsite notes") }
      let!(:picture) { FactoryBot.create(:picture, team: team, name: "Beach View") }

      before do
        FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: picture, position: 1)
        FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: thought, position: 2)
      end

      it "renders a successful response displaying the first picture and omitting other entries" do
        get current_team_chronicles_url
        expect(response).to be_successful
        expect(response.body).to include("Roadtrip through Andalusia")
        expect(response.body).to include("Beach View")
        expect(response.body).not_to include("Secret campsite notes")
      end
    end
  end

  describe "GET /show" do
    let!(:chronicle) { Chronicle.create!(valid_attributes) }
    let!(:thought) { FactoryBot.create(:thought, team: team, text: "Sunset at the campsite") }
    let!(:picture) { FactoryBot.create(:picture, team: team, name: "Beach View") }

    before do
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: picture, position: 1)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: thought, position: 2)
    end

    it "renders a successful response displaying all associated entries in position order after the notice" do
      get current_team_chronicle_url(chronicle.urlsafe_id)
      expect(response).to be_successful

      notice_index = response.body.index(chronicle.notice)
      entry1_index = response.body.index("Beach View")
      entry2_index = response.body.index("Sunset at the campsite")

      expect(notice_index).to be < entry1_index
      expect(entry1_index).to be < entry2_index
    end

    it "links attached pictures to current_team_picture_path instead of failing public route (regression test)" do
      picture.update!(visibility: "internal")
      get current_team_chronicle_url(chronicle.urlsafe_id)
      expect(response).to be_successful
      expect(response.body).to include(current_team_picture_path(picture))
      expect(response.body).not_to include(team_picture_only_path(team, picture))

      get current_team_picture_path(picture)
      expect(response).to be_successful
    end

    it "renders a visibility dropdown and allows changing visibility" do
      get current_team_chronicle_url(chronicle.urlsafe_id)
      expect(response).to be_successful
      expect(response.body).to include("Change visibility")
      expect(response.body).to include("dropdown")
      expect(response.body).to include("Published")

      patch current_team_content_visibility_url(chronicle), params: { visibility: "published" },
        headers: { "HTTP_REFERER" => current_team_chronicle_url(chronicle.urlsafe_id) }
      expect(response).to redirect_to(current_team_chronicle_url(chronicle.urlsafe_id))
      expect(chronicle.reload.visibility).to eq("published")
    end

    it "displays all attached pictures when multiple pictures are attached to a chronicle (regression test)" do
      second_pic = FactoryBot.create(:picture, team: team, name: "Sunset Over Alhambra")
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: second_pic, position: 3)

      get current_team_chronicle_url(chronicle.urlsafe_id)
      expect(response).to be_successful
      expect(response.body).to include("Beach View")
      expect(response.body).to include("Sunset Over Alhambra")
      expect(response.body.scan('article id="picture_').count).to eq(2)

      # Insight individual action buttons should be suppressed in chronicle show
      expect(response.body).not_to include("Show this picture")
      expect(response.body).not_to include("Edit this picture")
    end
  end

  describe "GET /new" do
    it "renders a successful response" do
      get new_current_team_chronicle_url
      expect(response).to be_successful
    end

    it "renders picture options with valid representation preview URLs and thumbnail images (regression test)" do
      FactoryBot.create(:picture, team: team, name: "Mountain View")
      get new_current_team_chronicle_url
      expect(response).to be_successful
      expect(response.body).to include("data-thumb-url=\"/rails/active_storage/representations/")
      expect(response.body).to include("Mountain View")
    end
  end

  describe "GET /edit" do
    let!(:chronicle) { Chronicle.create!(valid_attributes) }

    it "renders a successful response" do
      get edit_current_team_chronicle_url(chronicle.urlsafe_id)
      expect(response).to be_successful
    end

    it "renders picture options with valid representation preview URLs and thumbnail images (regression test)" do
      FactoryBot.create(:picture, team: team, name: "Mountain View")
      get edit_current_team_chronicle_url(chronicle.urlsafe_id)
      expect(response).to be_successful
      expect(response.body).to include("data-thumb-url=\"/rails/active_storage/representations/")
      expect(response.body).to include("Mountain View")
    end

    it "renders edit form with attached entries, edit links and remove checkboxes (regression test)",
      aggregate_failures: true do
      attached_pic1 = FactoryBot.create(:picture, team: team, name: "First Attached Picture")
      attached_pic2 = FactoryBot.create(:picture, team: team, name: "Second Attached Picture")
      entry1 = FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: attached_pic1, position: 1)
      entry2 = FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: attached_pic2, position: 2)

      get edit_current_team_chronicle_url(chronicle.urlsafe_id)
      expect(response).to be_successful
      expect(response.body).to include("Attached Entries")
      expect(response.body).to include("First Attached Picture")
      expect(response.body).to include("Second Attached Picture")
      expect(response.body).to include(edit_current_team_picture_path(attached_pic1))
      expect(response.body).to include(edit_current_team_picture_path(attached_pic2))
      expect(response.body).to include("chronicle[entries_attributes]")
      expect(response.body).to include(ActionView::RecordIdentifier.dom_id(entry1))
      expect(response.body).to include(ActionView::RecordIdentifier.dom_id(entry2))
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      let(:thought) { FactoryBot.create(:thought, team: team) }
      let(:picture) { FactoryBot.create(:picture, team: team) }

      let(:create_params) do
        {
          name: "Highlands Trekking",
          notice: "Crossing the Scottish Highlands through rain and sunshine with great company.",
          start_date: "2026-09-01",
          end_date: "2026-09-10",
          visibility: "internal",
          entries_attributes: [
            { entry_type: "Picture", entry_id: picture.id, position: 1 },
            { entry_type: "Thought", entry_id: thought.id, position: 2 },
          ],
        }
      end

      it "creates a new Chronicle and nested entries, and emits a RecordEvent", aggregate_failures: true do
        expect {
          post current_team_chronicles_url, params: { chronicle: create_params }
        }.to change { Chronicle.count }.by(1)
          .and change { ChronicleEntry.count }.by(2)
          .and change { RecordEvent.count }.by(1)

        chronicle = Chronicle.first
        expect(chronicle.name).to eq("Highlands Trekking")
        expect(chronicle.pictures).to include(picture)
        expect(chronicle.thoughts).to include(thought)
      end

      it "redirects to the created chronicle" do
        post current_team_chronicles_url, params: { chronicle: create_params }
        expect(response).to redirect_to(current_team_chronicle_url(Chronicle.first.urlsafe_id))
      end

      it "attaches an existing picture via picture_id param" do
        expect {
          post current_team_chronicles_url, params: {
            chronicle: valid_attributes.merge(picture_id: picture.id),
          }
        }.to change { Chronicle.count }.by(1).and change { ChronicleEntry.count }.by(1)

        chronicle = Chronicle.first
        expect(chronicle.pictures).to include(picture)
        expect(chronicle.entries.last.position).to eq(1)
      end

      it "attaches a newly uploaded picture via picture_file and picture_name" do
        uploaded_file = Rack::Test::UploadedFile.new(
          Rails.root.join("spec/support/macbookair_stickered.jpg"),
          "image/jpeg"
        )

        expect {
          post current_team_chronicles_url, params: {
            chronicle: valid_attributes.merge(
              picture_file: uploaded_file,
              picture_name: "MacBook on Desk"
            ),
          }
        }.to change { Chronicle.count }.by(1)
          .and change { Picture.count }.by(1)
          .and change { ChronicleEntry.count }.by(1)

        chronicle = Chronicle.first
        created_pic = Picture.last
        expect(created_pic.name).to eq("MacBook on Desk")
        expect(chronicle.pictures).to include(created_pic)
      end

      it "attaches existing and new Location, Thought, and Weblink on create" do
        loc = FactoryBot.create(:location, team: team, name: "Basecamp")
        FactoryBot.create(:thought, team: team, text: "Existing reflection")
        FactoryBot.create(:weblink, team: team, name: "Docs", url: "https://docs.example.com")

        expect {
          post current_team_chronicles_url, params: {
            chronicle: valid_attributes.merge(
              location_id: loc.id,
              thought_text: "New journey insight",
              weblink_url: "https://newsite.example.com",
              weblink_name: "New Site"
            ),
          }
        }.to change { Chronicle.count }.by(1)
          .and change { Thought.count }.by(1)
          .and change { Weblink.count }.by(1)
          .and change { ChronicleEntry.count }.by(3)

        chronicle = Chronicle.first
        expect(chronicle.locations).to include(loc)
        expect(chronicle.thoughts.pluck(:text)).to include("New journey insight")
        expect(chronicle.weblinks.pluck(:name)).to include("New Site")
      end

      it "attaches multiple sequential entry_ids on create" do
        pic = FactoryBot.create(:picture, team: team, name: "Sunset Horizon")
        loc = FactoryBot.create(:location, team: team, name: "Desert Camp")

        expect {
          post current_team_chronicles_url, params: {
            chronicle: valid_attributes.merge(
              entry_ids: [pic.id, loc.id]
            ),
          }
        }.to change { Chronicle.count }.by(1)
          .and change { ChronicleEntry.count }.by(2)

        chronicle = Chronicle.first
        expect(chronicle.pictures).to include(pic)
        expect(chronicle.locations).to include(loc)
      end
    end

    context "with invalid parameters" do
      it "does not create a new Chronicle" do
        expect {
          post current_team_chronicles_url, params: { chronicle: invalid_attributes }
        }.not_to(change { Chronicle.count })
      end

      it "renders a response with 422 status (unprocessable_content)" do
        post current_team_chronicles_url, params: { chronicle: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when member has unauthorized role (publisher)" do
      before { member.update!(roles: %w[publisher]) }

      it "forbids creating a chronicle with 403 Forbidden" do
        post current_team_chronicles_url, params: { chronicle: valid_attributes }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PATCH /update" do
    let!(:chronicle) { Chronicle.create!(valid_attributes) }
    let!(:thought) { FactoryBot.create(:thought, team: team) }
    let!(:entry) { FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: thought, position: 1) }

    context "with valid parameters" do
      let(:new_attributes) do
        {
          name: "Updated Andalusian Journey",
          notice: "An updated and expanded notice about the journey through the mountains.",
        }
      end

      it "updates the requested chronicle and emits an updated RecordEvent" do
        expect {
          patch current_team_chronicle_url(chronicle.urlsafe_id), params: { chronicle: new_attributes }
        }.to change { RecordEvent.count }.by(1)

        chronicle.reload
        expect(chronicle.name).to eq("Updated Andalusian Journey")
        expect(chronicle.notice).to eq("An updated and expanded notice about the journey through the mountains.")

        event = RecordEvent.last
        expect(event.name).to eq("updated")
        expect(event.record_id).to eq(chronicle.id)
      end

      it "attaches an existing picture via picture_id during update" do
        new_pic = FactoryBot.create(:picture, team: team, name: "Sunset at Alhambra")

        expect {
          patch current_team_chronicle_url(chronicle.urlsafe_id), params: {
            chronicle: new_attributes.merge(picture_id: new_pic.id),
          }
        }.to change { chronicle.entries.count }.by(1)

        entries = chronicle.reload.entries.reorder(position: :asc)
        expect(entries.map(&:entry)).to eq([thought, new_pic])
        expect(entries.map(&:position)).to eq([1, 2])
      end

      it "attaches a second picture to a chronicle already having a picture and displays both on show (regression test)" do
        first_pic = FactoryBot.create(:picture, team: team, name: "First Picture")
        chronicle_with_pic = Chronicle.create!(valid_attributes.merge(name: "Chronicle with Multiple Pictures"))
        FactoryBot.create(:chronicle_entry, chronicle: chronicle_with_pic, team: team, entry: first_pic, position: 1)

        second_pic = FactoryBot.create(:picture, team: team, name: "Second Picture")

        expect {
          patch current_team_chronicle_url(chronicle_with_pic.urlsafe_id), params: {
            chronicle: { picture_id: second_pic.urlsafe_id },
          }
        }.to change { chronicle_with_pic.entries.count }.by(1)

        expect(response).to redirect_to(current_team_chronicle_url(chronicle_with_pic.urlsafe_id))
        follow_redirect!
        expect(response.body).to include("First Picture")
        expect(response.body).to include("Second Picture")
        expect(response.body.scan('article id="picture_').count).to eq(2)
      end

      it "removes an attached picture entry via _destroy nested attribute (regression test)" do
        pic1 = FactoryBot.create(:picture, team: team, name: "Keep Picture")
        pic2 = FactoryBot.create(:picture, team: team, name: "Remove Picture")
        chronicle_with_pics = Chronicle.create!(valid_attributes.merge(name: "Chronicle to Detach Entries"))
        entry1 = FactoryBot.create(:chronicle_entry, chronicle: chronicle_with_pics, team: team, entry: pic1, position: 1)
        entry2 = FactoryBot.create(:chronicle_entry, chronicle: chronicle_with_pics, team: team, entry: pic2, position: 2)

        expect {
          patch current_team_chronicle_url(chronicle_with_pics.urlsafe_id), params: {
            chronicle: {
              entries_attributes: {
                "0" => { id: entry1.id, _destroy: "0" },
                "1" => { id: entry2.id, _destroy: "1" },
              },
            },
          }
        }.to change { chronicle_with_pics.entries.count }.by(-1)

        expect(chronicle_with_pics.reload.pictures).to eq([pic1])
        expect(Picture.exists?(pic2.id)).to be true
      end

      it "reorders attached entries via nested position attributes" do
        pic1 = FactoryBot.create(:picture, team: team, name: "First Picture")
        loc1 = FactoryBot.create(:location, team: team, name: "Second Location")
        th1 = FactoryBot.create(:thought, team: team, text: "Third Thought")
        chronicle_to_reorder = Chronicle.create!(valid_attributes.merge(name: "Reorder Chronicle"))
        e1 = FactoryBot.create(:chronicle_entry, chronicle: chronicle_to_reorder, team: team, entry: pic1, position: 1)
        e2 = FactoryBot.create(:chronicle_entry, chronicle: chronicle_to_reorder, team: team, entry: loc1, position: 2)
        e3 = FactoryBot.create(:chronicle_entry, chronicle: chronicle_to_reorder, team: team, entry: th1, position: 3)

        patch current_team_chronicle_url(chronicle_to_reorder.urlsafe_id), params: {
          chronicle: {
            entries_attributes: {
              "0" => { id: e1.id, position: 3 },
              "1" => { id: e2.id, position: 1 },
              "2" => { id: e3.id, position: 2 },
            },
          },
        }

        expect(response).to redirect_to(current_team_chronicle_url(chronicle_to_reorder.urlsafe_id))
        entries = chronicle_to_reorder.reload.entries.reorder(position: :asc)
        expect(entries.map(&:entry)).to eq([loc1, th1, pic1])
        expect(entries.map(&:position)).to eq([1, 2, 3])
      end

      it "attaches an uploaded picture via picture_file during update" do
        uploaded_file = Rack::Test::UploadedFile.new(
          Rails.root.join("spec/support/macbookair_stickered.jpg"),
          "image/jpeg"
        )

        expect {
          patch current_team_chronicle_url(chronicle.urlsafe_id), params: {
            chronicle: new_attributes.merge(
              picture_file: uploaded_file,
              picture_name: "Laptop in Granada"
            ),
          }
        }.to change { Picture.count }.by(1).and change { chronicle.entries.count }.by(1)

        created_pic = Picture.last
        expect(created_pic.name).to eq("Laptop in Granada")
        expect(chronicle.reload.pictures).to include(created_pic)
      end

      it "attaches Location, Thought, and Weblink during update" do
        loc = FactoryBot.create(:location, team: team)

        expect {
          patch current_team_chronicle_url(chronicle.urlsafe_id), params: {
            chronicle: new_attributes.merge(
              location_id: loc.id,
              thought_text: "Updated revelation",
              weblink_url: "https://update.example.com",
              weblink_name: "Update Source"
            ),
          }
        }.to change { Thought.count }.by(1)
          .and change { Weblink.count }.by(1)
          .and change { chronicle.entries.count }.by(3)

        expect(chronicle.reload.locations).to include(loc)
        expect(chronicle.thoughts.pluck(:text)).to include("Updated revelation")
        expect(chronicle.weblinks.pluck(:name)).to include("Update Source")
      end

      it "attaches both an existing picture and a newly uploaded picture during create and edit in sequence",
        aggregate_failures: true do
        existing_pic1 = FactoryBot.create(:picture, team: team, name: "Existing Picture 1")
        existing_pic2 = FactoryBot.create(:picture, team: team, name: "Existing Picture 2")
        existing_pic3 = FactoryBot.create(:picture, team: team, name: "Existing Picture 3")
        uploaded_file1 = Rack::Test::UploadedFile.new(
          Rails.root.join("spec/support/macbookair_stickered.jpg"),
          "image/jpeg"
        )
        uploaded_file2 = Rack::Test::UploadedFile.new(
          Rails.root.join("spec/support/macbookair_stickered.jpg"),
          "image/jpeg"
        )

        # Step 1: Create chronicle with existing_pic1 AND uploaded_file1
        post current_team_chronicles_url, params: {
          chronicle: valid_attributes.merge(
            name: "Full Journey Chronicle",
            picture_id: existing_pic1.id,
            picture_file: uploaded_file1,
            picture_name: "Uploaded Pic 1"
          ),
        }
        expect(response).to have_http_status(:redirect)
        created_chronicle = Chronicle.find_by(name: "Full Journey Chronicle")
        expect(created_chronicle.entries.count).to eq(2)
        expect(created_chronicle.entries.map(&:position)).to eq([1, 2])

        # Step 2: Edit and add existing_pic2
        patch current_team_chronicle_url(created_chronicle.urlsafe_id), params: {
          chronicle: {
            picture_id: existing_pic2.id,
          },
        }
        expect(response).to redirect_to(current_team_chronicle_url(created_chronicle.urlsafe_id))
        expect(created_chronicle.reload.entries.count).to eq(3)
        expect(created_chronicle.entries.map(&:position)).to eq([1, 2, 3])

        # Step 3: Edit and add existing_pic3
        patch current_team_chronicle_url(created_chronicle.urlsafe_id), params: {
          chronicle: {
            picture_id: existing_pic3.id,
          },
        }
        expect(response).to redirect_to(current_team_chronicle_url(created_chronicle.urlsafe_id))
        expect(created_chronicle.reload.entries.count).to eq(4)
        expect(created_chronicle.entries.map(&:position)).to eq([1, 2, 3, 4])

        # Step 4: Edit and upload a new picture (uploaded_file2)
        patch current_team_chronicle_url(created_chronicle.urlsafe_id), params: {
          chronicle: {
            picture_file: uploaded_file2,
            picture_name: "Uploaded Pic 2",
          },
        }
        expect(response).to redirect_to(current_team_chronicle_url(created_chronicle.urlsafe_id))
        expect(created_chronicle.reload.entries.count).to eq(5)
        expect(created_chronicle.entries.map(&:position)).to eq([1, 2, 3, 4, 5])
        expect(created_chronicle.entries.last.entry.name).to eq("Uploaded Pic 2")

        # Verify show view renders entries in ascending position order
        get current_team_chronicle_url(created_chronicle.urlsafe_id)
        expect(response).to be_successful
        expect(response.body).to include("Uploaded Pic 1")
        expect(response.body).to include("Existing Picture 1")
        expect(response.body).to include("Existing Picture 2")
        expect(response.body).to include("Existing Picture 3")
        expect(response.body).to include("Uploaded Pic 2")
      end

      it "redirects to the chronicle" do
        patch current_team_chronicle_url(chronicle.urlsafe_id), params: { chronicle: new_attributes }
        expect(response).to redirect_to(current_team_chronicle_url(chronicle.urlsafe_id))
      end
    end

    context "with invalid parameters" do
      it "renders a response with 422 status" do
        patch current_team_chronicle_url(chronicle.urlsafe_id), params: { chronicle: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /destroy" do
    let!(:chronicle) { Chronicle.create!(valid_attributes) }
    let!(:thought) { FactoryBot.create(:thought, team: team) }
    let!(:entry) { FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: thought, position: 1) }

    context "when member has authorized role (owner/manager)" do
      before { member.update!(roles: %w[owner]) }

      it "destroys the requested chronicle, its entries, and emits a deleted RecordEvent" do
        expect {
          delete current_team_chronicle_url(chronicle.urlsafe_id)
        }.to change { Chronicle.count }.by(-1)
          .and change { ChronicleEntry.count }.by(-1)
          .and change { RecordEvent.count }.by(1)

        event = RecordEvent.last
        expect(event.name).to eq("deleted")
        expect(event.record_id).to eq(chronicle.id)
      end

      it "redirects to the chronicles list" do
        delete current_team_chronicle_url(chronicle.urlsafe_id)
        expect(response).to redirect_to(current_team_chronicles_url)
      end
    end

    context "when member has unauthorized role (editor)" do
      before { member.update!(roles: %w[editor]) }

      it "forbids deleting a chronicle with 403 Forbidden" do
        delete current_team_chronicle_url(chronicle.urlsafe_id)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "Multi-tenant Isolation" do
    let(:other_team) { FactoryBot.create(:team) }
    let!(:other_chronicle) { FactoryBot.create(:chronicle, team: other_team) }

    it "cannot view another team's chronicle" do
      get current_team_chronicle_url(other_chronicle.urlsafe_id)
      expect(response).to have_http_status(:not_found).or have_http_status(:forbidden)
    end

    it "cannot edit another team's chronicle" do
      get edit_current_team_chronicle_url(other_chronicle.urlsafe_id)
      expect(response).to have_http_status(:not_found).or have_http_status(:forbidden)
    end
  end
end
