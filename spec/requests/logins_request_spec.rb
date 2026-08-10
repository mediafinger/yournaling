# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/logins", type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:other_user) { FactoryBot.create(:user) }
  let!(:login) { Login.create!(user: user, ip_address: "127.0.0.1", user_agent: "Firefox") }
  let!(:other_login) { Login.create!(user: other_user, ip_address: "10.0.0.1", user_agent: "Safari") }

  before do
    allow(Requests::GeoapifyIpLocationService).to receive(:call).and_return(["Madrid", "🇪🇸", "Spain"])
  end

  describe "GET /index" do
    context "when authenticated" do
      before do
        post login_path,
          params: { email: user.email, password: "foobar1234" },
          headers: { "HTTP_USER_AGENT" => "Firefox" }
      end

      it "renders a successful response listing the user's logins" do
        get login_records_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Firefox")
      end
    end

    context "when unauthenticated" do
      it "returns 403 forbidden" do
        get login_records_path

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "DELETE /destroy" do
    before do
      post login_path,
        params: { email: user.email, password: "foobar1234" },
        headers: { "HTTP_USER_AGENT" => "Firefox" }
    end

    it "allows the user to destroy their own login session" do
      expect {
        delete login_record_path(login)
      }.to change { Login.count }.by(-1)

      expect(response).to redirect_to(login_records_url)
    end

    it "forbids deleting another user's login session" do
      delete login_record_path(other_login)

      expect(response).to have_http_status(:forbidden)
      expect(Login.where(id: other_login.id)).to exist
    end
  end
end
