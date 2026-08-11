# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Namespace Access Control", type: :request do
  let(:regular_user) { FactoryBot.create(:user) }
  let(:admin_user) { FactoryBot.create(:user, role: "admin") }
  let(:admin_paths) do
    %w[
      /admin
      /admin/users
      /admin/teams
      /admin/locations
      /admin/pictures
      /admin/thoughts
      /admin/weblinks
      /admin/members
      /admin/record_events
    ]
  end

  describe "when user is unauthenticated (guest)" do
    it "returns 404 Not Found for all admin endpoints" do
      admin_paths.each do |admin_path|
        get admin_path
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "when user is authenticated as a regular non-admin" do
    before { sign_in(regular_user) }

    it "returns 404 Not Found for all admin endpoints" do
      admin_paths.each do |admin_path|
        get admin_path
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "when user is authenticated as an admin" do
    before { sign_in(admin_user) }

    it "renders successful response for all admin endpoints" do
      admin_paths.each do |admin_path|
        get admin_path
        expect(response).to be_successful
      end
    end
  end
end
