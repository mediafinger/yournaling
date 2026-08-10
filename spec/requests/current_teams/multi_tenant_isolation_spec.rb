# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Multi-Tenant Cross-Team Isolation", type: :request do
  let(:team_a) { FactoryBot.create(:team) }
  let(:team_b) { FactoryBot.create(:team) }

  let(:user_a) { FactoryBot.create(:user) }
  let(:user_b) { FactoryBot.create(:user) }

  let!(:member_a) { Member.create!(team: team_a, user: user_a, roles: %w[owner]) }
  let!(:member_b) { Member.create!(team: team_b, user: user_b, roles: %w[owner]) }

  # Records belonging to Team B
  let(:foreign_location) { FactoryBot.create(:location, team: team_b, name: "Secret B Spot") }
  let(:foreign_picture) { FactoryBot.create(:picture, team: team_b, name: "Secret B Pic") }
  let(:foreign_weblink) { FactoryBot.create(:weblink, team: team_b, name: "Secret B Link") }
  let(:foreign_memory) do
    FactoryBot.create(
      :memory,
      team: team_b,
      memo: "Secret B Memo",
      weblink: foreign_weblink,
      visibility: "internal"
    )
  end

  before do
    sign_in(user_a)
    switch_current_team(team_a)
  end

  describe "Locations isolation" do
    it "does not allow reading Team B's location" do
      get current_team_location_url(foreign_location)
      expect(response).to have_http_status(:not_found)
    end

    it "does not allow editing Team B's location" do
      get edit_current_team_location_url(foreign_location)
      expect(response).to have_http_status(:not_found)
    end

    it "does not allow updating Team B's location" do
      patch current_team_location_url(foreign_location), params: { location: { name: "Hacked" } }
      expect(response).to have_http_status(:not_found)
      expect(foreign_location.reload.name).to eq("Secret B Spot")
    end

    it "does not allow destroying Team B's location" do
      delete current_team_location_url(foreign_location)
      expect(response).to have_http_status(:not_found)
      expect(Location.find_by(id: foreign_location.id)).to be_present
    end
  end

  describe "Pictures isolation" do
    it "does not allow editing Team B's picture" do
      get edit_current_team_picture_url(foreign_picture.urlsafe_id)
      expect(response).to have_http_status(:forbidden)
    end

    it "does not allow updating Team B's picture" do
      patch current_team_picture_url(foreign_picture.urlsafe_id), params: { picture: { name: "Hacked" } }
      expect(response).to have_http_status(:forbidden)
      expect(foreign_picture.reload.name).to eq("Secret B Pic")
    end

    it "does not allow destroying Team B's picture" do
      delete current_team_picture_url(foreign_picture.urlsafe_id)
      expect(response).to have_http_status(:forbidden)
      expect(Picture.find_by(id: foreign_picture.id)).to be_present
    end
  end

  describe "Memories isolation" do
    it "does not allow reading Team B's internal memory" do
      get current_team_memory_url(foreign_memory.urlsafe_id)
      expect(response).to have_http_status(:forbidden)
    end

    it "does not allow editing Team B's memory" do
      get edit_current_team_memory_url(foreign_memory.urlsafe_id)
      expect(response).to have_http_status(:forbidden)
    end

    it "does not allow updating Team B's memory" do
      patch current_team_memory_url(foreign_memory.urlsafe_id), params: { memory: { memo: "Hacked" } }
      expect(response).to have_http_status(:forbidden)
      expect(foreign_memory.reload.memo).to eq("Secret B Memo")
    end

    it "does not allow destroying Team B's memory" do
      delete current_team_memory_url(foreign_memory.urlsafe_id)
      expect(response).to have_http_status(:forbidden)
      expect(Memory.find_by(id: foreign_memory.id)).to be_present
    end
  end

  describe "Weblinks isolation" do
    it "does not allow editing Team B's weblink" do
      get edit_current_team_weblink_url(foreign_weblink)
      expect(response).to have_http_status(:forbidden)
    end

    it "does not allow updating Team B's weblink" do
      patch current_team_weblink_url(foreign_weblink), params: { weblink: { name: "Hacked" } }
      expect(response).to have_http_status(:forbidden)
      expect(foreign_weblink.reload.name).to eq("Secret B Link")
    end

    it "does not allow destroying Team B's weblink" do
      delete current_team_weblink_url(foreign_weblink)
      expect(response).to have_http_status(:forbidden)
      expect(Weblink.find_by(id: foreign_weblink.id)).to be_present
    end
  end

  describe "Members isolation" do
    it "does not allow editing Team B's membership" do
      get edit_current_team_member_url(member_b.urlsafe_id)
      expect(response).to have_http_status(:forbidden)
    end

    it "does not allow updating Team B's membership" do
      patch current_team_member_url(member_b.urlsafe_id), params: { member: { roles: %w[manager] } }
      expect(response).to have_http_status(:forbidden)
      expect(member_b.reload.roles).to eq(%w[owner])
    end

    it "does not allow destroying Team B's membership" do
      delete current_team_member_url(member_b.urlsafe_id)
      expect(response).to have_http_status(:forbidden)
      expect(Member.find_by(id: member_b.id)).to be_present
    end
  end
end
