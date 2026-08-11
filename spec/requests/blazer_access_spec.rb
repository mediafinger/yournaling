# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Blazer Analytics Dashboard Access Control", type: :request do
  let(:regular_user) { FactoryBot.create(:user, role: "user") }
  let(:admin_user) { FactoryBot.create(:user, role: "admin") }

  describe "when user is unauthenticated (guest)" do
    it "returns 404 Not Found for /admin/blazer" do
      get "/admin/blazer"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "when user is authenticated as a regular non-admin" do
    before { sign_in(regular_user) }

    it "returns 404 Not Found for /admin/blazer" do
      get "/admin/blazer"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "when user is authenticated as an admin" do
    before { sign_in(admin_user) }

    it "renders successful response for /admin/blazer/" do
      get "/admin/blazer/"
      expect(response).to be_successful
    end

    it "renders successful response for /admin/blazer/queries/new" do
      get "/admin/blazer/queries/new"
      expect(response).to be_successful
    end

    it "creates a new query successfully" do
      expect {
        post "/admin/blazer/queries", params: {
          query: {
            name: "Recent Users",
            statement: "SELECT id, name, email FROM users ORDER BY created_at DESC LIMIT 5",
            data_source: "main",
          },
        }
      }.to change { Blazer::Query.count }.by(1)

      expect(response).to be_redirect
    end
  end
end
