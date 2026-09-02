# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/admin/memories", type: :request do
  let(:admin_user) { FactoryBot.create(:user, role: "admin") }
  let(:team) { FactoryBot.create(:team) }

  before { sign_in(admin_user) }

  describe "GET /admin/memories" do
    it "renders a successful response" do
      FactoryBot.create(:memory, team: team)
      get admin_memories_url
      expect(response).to be_successful
    end
  end

  describe "GET /admin/memories/:id" do
    it "renders a successful response" do
      memory = FactoryBot.create(:memory, team: team)
      get admin_memory_url(memory)
      expect(response).to be_successful
    end
  end

  describe "GET /admin/memories/new" do
    it "renders a successful response" do
      get new_admin_memory_url
      expect(response).to be_successful
    end
  end

  describe "GET /admin/memories/:id/edit" do
    it "renders a successful response" do
      memory = FactoryBot.create(:memory, team: team)
      get edit_admin_memory_url(memory)
      expect(response).to be_successful
    end
  end

  describe "POST /admin/memories" do
    let(:valid_attributes) { { memo: "Admin curated memory", visibility: "draft", team_id: team.id } }

    it "creates a Memory and a done_by_admin RecordEvent, then redirects" do
      expect {
        post admin_memories_url, params: { memory: valid_attributes }
      }.to change { Memory.count }.by(1).and change { RecordEvent.count }.by(1)

      expect(RecordEvent.last).to have_attributes(name: "created", done_by_admin: true)
      expect(response).to redirect_to(admin_memory_url(Memory.last))
    end

    it "renders 422 for invalid parameters" do
      post admin_memories_url, params: { memory: { memo: nil, visibility: nil, team_id: nil } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /admin/memories/:id" do
    it "updates the memory and redirects" do
      memory = FactoryBot.create(:memory, team: team, memo: "Original")
      patch admin_memory_url(memory), params: { memory: { memo: "Admin edited" } }

      expect(memory.reload.memo).to eq("Admin edited")
      expect(response).to redirect_to(admin_memory_url(memory))
    end
  end

  describe "DELETE /admin/memories/:id" do
    it "destroys the memory and emits a deleted RecordEvent" do
      memory = FactoryBot.create(:memory, team: team)

      expect {
        delete admin_memory_url(memory)
      }.to change { Memory.count }.by(-1).and change { RecordEvent.count }.by(1)

      expect(RecordEvent.last).to have_attributes(name: "deleted", done_by_admin: true)
    end
  end
end
