# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/current_team/thoughts", type: :request do
  let!(:member) { Member.create!(team: team, user: user, roles: Array(roles.sample)) }

  let(:team) { FactoryBot.create(:team) }
  let(:user) { FactoryBot.create(:user) }
  let(:roles) { %i[owner manager editor] }

  let(:valid_attributes) { { text: "Just had a profound revelation today.", date: Date.current, team: team } }
  let(:invalid_attributes) { { text: nil, date: nil } }

  before do
    sign_in(user)
    switch_current_team(team)
  end

  describe "GET /index" do
    it "renders a successful response" do
      Thought.create!(valid_attributes)

      get current_team_thoughts_url

      expect(response).to be_successful
    end
  end

  describe "GET /show" do
    it "renders a successful response" do
      thought = Thought.create!(valid_attributes)

      get current_team_thought_url(thought)

      expect(response).to be_successful
    end
  end

  describe "GET /new" do
    it "renders a successful response" do
      get new_current_team_thought_url

      expect(response).to be_successful
    end
  end

  describe "GET /edit" do
    it "renders a successful response" do
      thought = Thought.create!(valid_attributes)

      get edit_current_team_thought_url(thought)

      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new Thought and emits a RecordEvent" do
        expect {
          post current_team_thoughts_url, params: { thought: { text: "A fresh new thought", date: Date.current } }
        }.to change { Thought.count }.by(1).and change { RecordEvent.count }.by(1)

        event = RecordEvent.last
        expect(event.name).to eq("created")
        expect(event.record_type).to eq("thot")
        expect(event.team_id).to eq(team.id)
        expect(event.user_id).to eq(user.id)
      end

      it "redirects to the created thought" do
        post current_team_thoughts_url, params: { thought: { text: "A fresh new thought", date: Date.current } }
        expect(response).to redirect_to(current_team_thought_url(Thought.first))
      end
    end

    context "with invalid parameters" do
      it "does not create a new Thought" do
        expect {
          post current_team_thoughts_url, params: { thought: invalid_attributes }
        }.not_to(change { Thought.count })
      end

      it "renders a response with 422 status (unprocessable_content)" do
        post current_team_thoughts_url, params: { thought: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with JSON format" do
      it "creates a thought and returns JSON response" do
        post current_team_thoughts_url(format: :json), params: { thought: valid_attributes }
        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json["id"]).to be_present
        expect(json["type"]).to eq("thought")
      end

      it "returns 422 with errors array when invalid" do
        post current_team_thoughts_url(format: :json), params: { thought: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
        json = response.parsed_body
        expect(json["errors"]).to be_present
      end
    end

    context "when member has unauthorized role (publisher)" do
      before { member.update!(roles: %w[publisher]) }

      it "forbids creating a thought with 403 Forbidden" do
        post current_team_thoughts_url, params: { thought: { text: "Unauthorized thought", date: Date.current } }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PATCH /update" do
    let!(:thought) { Thought.create!(valid_attributes) }

    context "with valid parameters" do
      let(:new_attributes) { { text: "Refined perspective on the topic." } }

      it "updates the requested thought and emits a RecordEvent" do
        expect {
          patch current_team_thought_url(thought), params: { thought: new_attributes }
        }.to change { RecordEvent.count }.by(1)

        thought.reload
        expect(thought.text).to eq("Refined perspective on the topic.")

        event = RecordEvent.last
        expect(event.name).to eq("updated")
        expect(event.record_id).to eq(thought.id)
      end

      it "redirects to the thought" do
        patch current_team_thought_url(thought), params: { thought: new_attributes }
        thought.reload
        expect(response).to redirect_to(current_team_thought_url(thought))
      end
    end

    context "with invalid parameters" do
      it "renders a response with 422 status" do
        patch current_team_thought_url(thought), params: { thought: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /destroy" do
    let!(:thought) { Thought.create!(valid_attributes) }

    context "when member has authorized role (owner/manager)" do
      before { member.update!(roles: %w[owner]) }

      it "destroys the requested thought and emits a deleted RecordEvent" do
        expect {
          delete current_team_thought_url(thought)
        }.to change { Thought.count }.by(-1).and change { RecordEvent.count }.by(1)

        event = RecordEvent.last
        expect(event.name).to eq("deleted")
        expect(event.record_id).to eq(thought.id)
      end

      it "redirects to the thoughts list" do
        delete current_team_thought_url(thought)
        expect(response).to redirect_to(current_team_thoughts_url)
      end
    end

    context "when member has unauthorized role (editor)" do
      before { member.update!(roles: %w[editor]) }

      it "forbids deleting a thought with 403 Forbidden" do
        delete current_team_thought_url(thought)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
