# frozen_string_literal: true

RSpec.describe "Email Verifications", type: :request do
  let(:user) { FactoryBot.create(:user) }

  describe "GET /email_verification/new" do
    # Regression guard: the routes for this controller were committed before the controller
    # existed, so every one of these paths raised ActionController::RoutingError at request time.
    it "renders a successful response" do
      get new_email_verification_path

      expect(response).to be_successful
    end
  end

  describe "GET /email_verification/:token" do
    context "with a valid token" do
      it "verifies the email address and redirects to login" do
        token = user.generate_token_for(:email_verification)

        expect {
          get show_email_verification_path(token:)
        }.to change { user.reload.email_verified? }.from(false).to(true)

        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to eq("Your email address is confirmed. Please sign in.")
      end

      # The token is single-use by construction: redeeming it rebinds the payload (see the
      # committed User spec, "can only be redeemed once"). A replay must therefore neither move
      # the timestamp nor blow up -- and, because mail scanners prefetch links, the copy the
      # replaying visitor sees has to leave "you are already confirmed" open as an explanation.
      it "leaves the verification untouched when the same token is replayed" do
        token = user.generate_token_for(:email_verification)
        get show_email_verification_path(token:)
        verified_at = user.reload.email_verified_at

        expect {
          get show_email_verification_path(token:)
        }.not_to(change { user.reload.email_verified_at })

        expect(verified_at).to be_present
        expect(response).to redirect_to(new_email_verification_path)
        expect(flash[:alert]).to include("already confirmed")
      end
    end

    context "with an unusable token" do
      it "rejects a garbage token without raising" do
        get show_email_verification_path(token: "not-a-real-token")

        expect(response).to redirect_to(new_email_verification_path)
        expect(flash[:alert]).to eq(EmailVerificationsController::INVALID_TOKEN_ALERT)
      end

      it "rejects a token that has outlived its validity" do
        token = user.generate_token_for(:email_verification)

        travel(User::EMAIL_VERIFICATION_TOKEN_VALIDITY + 1.day) do
          get show_email_verification_path(token:)

          expect(user.reload).not_to be_email_verified
          expect(response).to redirect_to(new_email_verification_path)
        end
      end

      # The token payload embeds the address, so changing it must strand outstanding links.
      it "rejects a token invalidated by an email change" do
        token = user.generate_token_for(:email_verification)
        user.update!(email: "moved@example.com")

        get show_email_verification_path(token:)

        expect(user.reload).not_to be_email_verified
        expect(response).to redirect_to(new_email_verification_path)
      end
    end
  end

  describe "POST /email_verification" do
    it "enqueues a fresh verification mail for an unverified user" do
      expect {
        post email_verification_path, params: { email: user.email }
      }.to change { SolidQueue::Job.count }.by(1)

      expect(SolidQueue::Job.last.arguments["arguments"]).to include("verify_email")
      expect(response).to redirect_to(login_path)
    end

    it "sends nothing for an already verified user" do
      verified = FactoryBot.create(:user, :email_verified)

      expect {
        post email_verification_path, params: { email: verified.email }
      }.not_to(change { SolidQueue::Job.count })
    end

    it "sends nothing for an unknown address" do
      expect {
        post email_verification_path, params: { email: "nobody@example.com" }
      }.not_to(change { SolidQueue::Job.count })
    end

    # All three branches above must be indistinguishable to the caller, or this endpoint becomes
    # an oracle for "is this address registered, and is it confirmed yet?".
    it "answers identically regardless of whether the address exists or is already verified" do
      verified = FactoryBot.create(:user, :email_verified)
      notices = [user.email, verified.email, "nobody@example.com"].map do |email|
        post email_verification_path, params: { email: }
        [response.status, response.location, flash[:notice]]
      end

      expect(notices.uniq.size).to eq(1)
      expect(notices.first.last).to be_present
    end

    it "refuses to keep resending once the hourly limit is spent" do
      4.times { post email_verification_path, params: { email: user.email } }

      expect(response).to have_http_status(:too_many_requests)
    end

    it "stops enqueueing mail once rate limited" do
      expect {
        6.times { post email_verification_path, params: { email: user.email } }
      }.to change { SolidQueue::Job.count }.by(3)
    end
  end
end
