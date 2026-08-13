# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User Passwords (Password Reset)", type: :request do
  let(:user) { FactoryBot.create(:user, password: "old_password1234") }

  describe "GET /user_password/new" do
    it "renders a successful response" do
      get new_user_password_path
      expect(response).to be_successful
    end
  end

  describe "POST /user_password" do
    context "when user exists" do
      it "enqueues a password reset email and redirects to login" do
        expect {
          post user_password_path, params: { email: user.email }
        }.to change { SolidQueue::Job.count }.by(1)

        job = SolidQueue::Job.last
        expect(job.class_name).to eq("ActionMailer::MailDeliveryJob")
        expect(job.arguments["arguments"]).to include("password_reset")
        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to be_present
      end
    end

    context "when user does not exist" do
      it "does not send an email but displays the same notice to prevent enumeration" do
        expect {
          post user_password_path, params: { email: "unknown@example.com" }
        }.not_to(change { SolidQueue::Job.count })

        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to be_present
      end
    end
  end

  describe "GET /user_password/edit/:token" do
    context "with a valid token" do
      it "renders a successful response" do
        token = user.generate_token_for(:password_reset)
        get edit_user_password_path(token:)
        expect(response).to be_successful
      end
    end

    context "with an invalid token" do
      it "redirects to request page with alert" do
        get edit_user_password_path(token: "invalid-token")
        expect(response).to redirect_to(new_user_password_path)
        expect(flash[:alert]).to eq("That password reset link is invalid or has expired.")
      end
    end

    context "with an expired token" do
      it "redirects to request page with alert" do
        token = user.generate_token_for(:password_reset)
        travel 20.minutes do
          get edit_user_password_path(token:)
          expect(response).to redirect_to(new_user_password_path)
          expect(flash[:alert]).to eq("That password reset link is invalid or has expired.")
        end
      end
    end
  end

  describe "PATCH /user_password/edit/:token" do
    context "with valid parameters" do
      it "updates the password, emits an event, and redirects to login" do
        token = user.generate_token_for(:password_reset)

        expect {
          patch edit_user_password_path(token:), params: { user: { password: "new_password1234" } }
        }.to change { RecordEvent.count }.by(1)

        expect(user.reload.authenticate("new_password1234")).to eq(user)
        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to eq("Your password has been reset successfully. Please sign in.")
      end

      it "invalidates the used token after password change" do
        token = user.generate_token_for(:password_reset)
        patch edit_user_password_path(token:), params: { user: { password: "new_password1234" } }

        # Old token can no longer be used
        get edit_user_password_path(token:)
        expect(response).to redirect_to(new_user_password_path)
      end
    end

    context "with invalid parameters (e.g. too short password)" do
      it "does not update password and renders 422 unprocessable_content" do
        token = user.generate_token_for(:password_reset)

        patch edit_user_password_path(token:), params: { user: { password: "short" } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(user.reload.authenticate("old_password1234")).to eq(user)
      end
    end

    context "with an expired token" do
      it "rejects update and redirects with alert" do
        token = user.generate_token_for(:password_reset)

        travel 20.minutes do
          patch edit_user_password_path(token:), params: { user: { password: "new_password1234" } }
          expect(response).to redirect_to(new_user_password_path)
          expect(flash[:alert]).to eq("That password reset link is invalid or has expired.")
        end
      end
    end
  end
end
