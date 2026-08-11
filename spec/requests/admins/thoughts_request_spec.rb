# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/admin/thoughts", type: :request do
  let(:admin_user) { FactoryBot.create(:user, role: "admin") }
  let(:regular_user) { FactoryBot.create(:user, role: "user") }
  let(:team) { FactoryBot.create(:team) }
  let(:valid_attributes) { { text: "Admin curated thought", date: Date.current, team_id: team.id } }
  let(:invalid_attributes) { { text: nil, date: nil, team_id: nil } }

  describe "when user is authenticated as an admin" do
    before { sign_in(admin_user) }

    describe "GET /admin/thoughts" do
      it "renders a successful response" do
        Thought.create!(text: "Thought 1", date: Date.current, team: team)
        get admin_thoughts_url
        expect(response).to be_successful
      end
    end

    describe "GET /admin/thoughts/:id" do
      it "renders a successful response" do
        thought = Thought.create!(text: "Thought 1", date: Date.current, team: team)
        get admin_thought_url(thought)
        expect(response).to be_successful
      end
    end

    describe "GET /admin/thoughts/new" do
      it "renders a successful response" do
        get new_admin_thought_url
        expect(response).to be_successful
      end
    end

    describe "GET /admin/thoughts/:id/edit" do
      it "renders a successful response" do
        thought = Thought.create!(text: "Thought 1", date: Date.current, team: team)
        get edit_admin_thought_url(thought)
        expect(response).to be_successful
      end
    end

    describe "POST /admin/thoughts" do
      context "with valid parameters" do
        it "creates a new Thought and emits a RecordEvent marked as done_by_admin" do
          expect {
            post admin_thoughts_url, params: { thought: valid_attributes }
          }.to change { Thought.count }.by(1).and change { RecordEvent.count }.by(1)

          event = RecordEvent.last
          expect(event.name).to eq("created")
          expect(event.done_by_admin).to be true
          expect(event.team_id).to eq("admin")
          expect(event.user_id).to eq(admin_user.id)
        end

        it "redirects to the created thought" do
          post admin_thoughts_url, params: { thought: valid_attributes }
          expect(response).to redirect_to(admin_thought_url(Thought.first))
        end
      end

      context "with invalid parameters" do
        it "does not create a new Thought" do
          expect {
            post admin_thoughts_url, params: { thought: invalid_attributes }
          }.not_to(change { Thought.count })
        end

        it "renders a response with 422 status (unprocessable_content)" do
          post admin_thoughts_url, params: { thought: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    describe "PATCH /admin/thoughts/:id" do
      let!(:thought) { Thought.create!(text: "Original thought", date: Date.current, team: team) }

      context "with valid parameters" do
        it "updates the thought and emits a RecordEvent" do
          expect {
            patch admin_thought_url(thought), params: { thought: { text: "Admin edited thought" } }
          }.to change { RecordEvent.count }.by(1)

          expect(thought.reload.text).to eq("Admin edited thought")
          event = RecordEvent.last
          expect(event.name).to eq("updated")
          expect(event.done_by_admin).to be true
        end

        it "redirects to the thought" do
          patch admin_thought_url(thought), params: { thought: { text: "Admin edited thought" } }
          expect(response).to redirect_to(admin_thought_url(thought))
        end
      end

      context "with invalid parameters" do
        it "renders a response with 422 status" do
          patch admin_thought_url(thought), params: { thought: { text: nil } }
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    describe "DELETE /admin/thoughts/:id" do
      let!(:thought) { Thought.create!(text: "Thought to delete", date: Date.current, team: team) }

      it "destroys the thought and emits a deleted RecordEvent" do
        expect {
          delete admin_thought_url(thought)
        }.to change { Thought.count }.by(-1).and change { RecordEvent.count }.by(1)

        event = RecordEvent.last
        expect(event.name).to eq("deleted")
        expect(event.done_by_admin).to be true
      end

      it "redirects to the thoughts list" do
        delete admin_thought_url(thought)
        expect(response).to redirect_to(admin_thoughts_url)
      end
    end
  end

  describe "when user is unauthenticated or not an admin" do
    it "returns 404 Not Found for non-admin" do
      sign_in(regular_user)
      get admin_thoughts_url
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 Not Found for guest" do
      get admin_thoughts_url
      expect(response).to have_http_status(:not_found)
    end
  end
end
