# frozen_string_literal: true

RSpec.describe "Registrations", type: :request do
  let(:name) { Faker::Name.unique.name }
  let(:email) { "#{name.parameterize.underscore}@example.com" }
  let(:valid_attributes) { { name:, email:, password: "foobar1234" } }

  describe "GET /register" do
    it "renders a successful response for a guest" do
      get new_registration_path

      expect(response).to be_successful
    end

    it "is forbidden for a visitor who already holds a session" do
      sign_in(FactoryBot.create(:user))

      get new_registration_path

      expect(response).to be_forbidden
    end
  end

  describe "POST /register" do
    context "with valid parameters" do
      it "creates the user" do
        expect {
          post registration_path, params: { user: valid_attributes }
        }.to change { User.count }.by(1)

        expect(User.last).to have_attributes(name:, email:)
      end

      it "records an audit event" do
        expect {
          post registration_path, params: { user: valid_attributes }
        }.to change { RecordEvent.count }.by(1)
      end

      it "enqueues the verification mail" do
        expect {
          post registration_path, params: { user: valid_attributes }
        }.to change { SolidQueue::Job.count }.by(1)

        expect(SolidQueue::Job.last.arguments["arguments"]).to include("verify_email")
      end

      it "leaves the new account unverified and redirects to login" do
        post registration_path, params: { user: valid_attributes }

        expect(User.last).not_to be_email_verified
        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to be_present
      end

      # Registration must not create a Team or a Member: that is an explicit, separate user action.
      it "does not create a team or a membership" do
        expect {
          post registration_path, params: { user: valid_attributes }
        }.to change { User.count }.by(1)

        expect(Team.count).to eq(0)
        expect(Member.count).to eq(0)
      end
    end

    context "with invalid parameters" do
      it "rejects a malformed email address" do
        expect {
          post registration_path, params: { user: valid_attributes.merge(email: "not-an-email") }
        }.not_to(change { User.count })

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "rejects a password below the minimum length" do
        expect {
          post registration_path, params: { user: valid_attributes.merge(password: "short") }
        }.not_to(change { User.count })

        expect(response).to have_http_status(:unprocessable_content)
      end

      # has_secure_password runs with `validations: false`, so a blank password would otherwise
      # surface only as "Password digest can't be blank", which is meaningless to a visitor.
      it "rejects a blank password with an error naming the password, not the digest" do
        expect {
          post registration_path, params: { user: valid_attributes.merge(password: "") }
        }.not_to(change { User.count })

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Password can&#39;t be blank").or include("Password can't be blank")
      end

      it "rejects an address that is already registered" do
        FactoryBot.create(:user, email:)

        expect {
          post registration_path, params: { user: valid_attributes }
        }.not_to(change { User.count })

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "re-renders the form rather than losing what was typed" do
        post registration_path, params: { user: valid_attributes.merge(password: "short") }

        expect(response.body).to include(email)
      end
    end

    # The highest-value security assertion on this branch: UserRegistrationService's
    # REGISTRABLE_ATTRIBUTES allow-list is the single chokepoint against privilege escalation,
    # and nothing proved it end-to-end over HTTP before now.
    context "when the request tries to assign privileged attributes" do
      it "ignores role and email_verified_at" do
        post registration_path, params: {
          user: valid_attributes.merge(role: "admin", email_verified_at: Time.current),
        }

        user = User.last
        expect(user.role).to eq("user")
        expect(user.email_verified_at).to be_nil
        expect(user).not_to be_admin
      end
    end

    context "when the visitor already holds a session" do
      it "is forbidden, and creates nothing" do
        sign_in(FactoryBot.create(:user))

        expect {
          post registration_path, params: { user: valid_attributes }
        }.not_to(change { User.count })

        expect(response).to be_forbidden
      end
    end

    context "when signups are coming in faster than the limit allows" do
      it "refuses the request once the hourly limit is spent" do
        6.times do |i|
          post registration_path, params: { user: valid_attributes.merge(email: "signup#{i}@example.com") }
        end

        expect(response).to have_http_status(:too_many_requests)
      end

      it "stops creating users once rate limited" do
        expect {
          8.times do |i|
            post registration_path, params: { user: valid_attributes.merge(email: "flood#{i}@example.com") }
          end
        }.to change { User.count }.by(5)
      end
    end
  end
end
