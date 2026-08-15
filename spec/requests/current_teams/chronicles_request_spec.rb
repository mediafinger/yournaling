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

    it "renders a successful response displaying all associated entries" do
      get current_team_chronicle_url(chronicle.urlsafe_id)
      expect(response).to be_successful
      expect(response.body).to include("Beach View")
      expect(response.body).to include("Sunset at the campsite")
    end
  end

  describe "GET /new" do
    it "renders a successful response" do
      get new_current_team_chronicle_url
      expect(response).to be_successful
    end
  end

  describe "GET /edit" do
    let!(:chronicle) { Chronicle.create!(valid_attributes) }

    it "renders a successful response" do
      get edit_current_team_chronicle_url(chronicle.urlsafe_id)
      expect(response).to be_successful
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
          chronicle_entries_attributes: [
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
