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
    end

    describe "GET /admin/chronicles/new" do
      it "renders a successful response" do
        get new_admin_chronicle_url
        expect(response).to be_successful
      end
    end

    describe "GET /admin/chronicles/:id/edit" do
      it "renders a successful response" do
        chronicle = Chronicle.create!(valid_attributes)
        get edit_admin_chronicle_url(chronicle)
        expect(response).to be_successful
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
      end

      context "with invalid parameters" do
        it "does not create a new Chronicle" do
          expect {
            post admin_chronicles_url, params: { chronicle: invalid_attributes }
          }.not_to(change { Chronicle.count })
        end

        it "renders a response with 422 status (unprocessable_content)" do
          post admin_chronicles_url, params: { chronicle: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    describe "PATCH /admin/chronicles/:id" do
      let!(:chronicle) { Chronicle.create!(valid_attributes) }

      context "with valid parameters" do
        it "updates the chronicle and emits a RecordEvent" do
          expect {
            patch admin_chronicle_url(chronicle), params: { chronicle: { name: "Admin Renamed Chronicle" } }
          }.to change { RecordEvent.count }.by(1)

          expect(chronicle.reload.name).to eq("Admin Renamed Chronicle")
          event = RecordEvent.last
          expect(event.name).to eq("updated")
          expect(event.done_by_admin).to be true
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
