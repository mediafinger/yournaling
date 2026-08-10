# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sessions & Device Tracking Lifecycle", type: :request do
  let(:user) { FactoryBot.create(:user, email: "nomad@example.com") }

  describe "GET /login" do
    it "renders the login page successfully" do
      get login_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /login" do
    context "with valid credentials" do
      it "signs in the user, creates a Login record, and sets session device_id" do
        post login_path,
          params: { email: user.email, password: "foobar1234" },
          headers: { "HTTP_USER_AGENT" => "Chrome on Mac", "REMOTE_ADDR" => "192.168.1.50" }

        expect(response).to redirect_to(root_url)
        expect(session[:user_id]).to eq(user.urlsafe_id)

        login_record = user.logins.first
        expect(login_record).to be_present
        expect(login_record.user_agent).to eq("Chrome on Mac")
        expect(session[:device_id]).to eq(login_record.device_id)
      end

      it "prunes older login sessions beyond NUMBER_OF_LOGIN_SESSIONS_TO_KEEP" do
        # Create 3 existing logins
        4.times do |i|
          Login.create!(
            user: user,
            ip_address: "10.0.0.#{i + 1}",
            user_agent: "Browser #{i + 1}",
            created_at: (i + 1).days.ago,
            updated_at: (i + 1).days.ago
          )
        end

        expect(user.logins.count).to eq(4)

        post login_path,
          params: { email: user.email, password: "foobar1234" },
          headers: { "HTTP_USER_AGENT" => "Newest Device", "REMOTE_ADDR" => "10.0.0.99" }

        expect(user.logins.reload.count).to eq(Logins::NUMBER_OF_LOGIN_SESSIONS_TO_KEEP)
        expect(user.logins.order(updated_at: :desc).first.user_agent).to eq("Newest Device")
      end
    end

    context "with invalid credentials" do
      it "returns 403 forbidden and does not set session" do
        post login_path, params: { email: user.email, password: "wrongpassword" }

        expect(response).to have_http_status(:forbidden)
        expect(session[:user_id]).to be_nil
        expect(user.logins.count).to eq(0)
      end
    end
  end

  describe "DELETE /logout" do
    before do
      post login_path,
        params: { email: user.email, password: "foobar1234" },
        headers: { "HTTP_USER_AGENT" => "Active Device" }
    end

    it "destroys the device Login record and clears the session" do
      expect(user.logins.count).to eq(1)

      delete logout_path

      expect(response).to redirect_to(root_url)
      expect(user.logins.reload.count).to eq(0)
      expect(session[:user_id]).to be_nil
      expect(session[:device_id]).to be_nil
    end
  end

  describe "remote session revocation (logout_if_login_record_has_been_deleted)" do
    it "logs out user when their Login record was destroyed remotely" do
      post login_path,
        params: { email: user.email, password: "foobar1234" },
        headers: { "HTTP_USER_AGENT" => "Session To Invalidate" }

      expect(session[:user_id]).to be_present

      # Simulate another device revoking this login
      user.logins.destroy_all

      # Subsequent request triggers logout_if_login_record_has_been_deleted
      get teams_path

      expect(response).to redirect_to(root_url)
      expect(session[:user_id]).to be_nil
    end
  end
end
