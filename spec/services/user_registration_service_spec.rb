# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserRegistrationService, type: :service do
  subject(:register) { described_class.call(attributes: attributes) }

  let(:valid_attributes) { { name: "Andy Vanlifer", email: "andy@example.com", password: "foobar1234" } }
  let(:attributes) { valid_attributes }

  describe ".call with valid attributes" do
    it "returns the persisted user" do
      expect(register).to be_a(User).and be_persisted
    end

    it "creates exactly one user" do
      expect { register }.to change { User.count }.by(1)
    end

    it "normalises the attributes through the model" do
      described_class.call(attributes: valid_attributes.merge(email: "  ANDY@EXAMPLE.COM ", name: " Andy  "))

      expect(User.last).to have_attributes(email: "andy@example.com", name: "Andy")
    end

    it "leaves the account unverified until the emailed link is redeemed" do
      expect(register.email_verified_at).to be_nil
    end

    it "records a self-service creation event in the audit trail" do
      expect { register }.to change { RecordEvent.count }.by(1)

      event = RecordEvent.last

      expect(event).to have_attributes(
        name: "created",
        record_type: User::YID_CODE,
        record_id: User.last.id,
        team_id: nil,
        done_by_admin: false
      )
      expect(event.user_id).to eq(User.last.id)
    end

    it "enqueues exactly one email verification mail" do
      expect { register }.to change { SolidQueue::Job.count }.by(1)

      job = SolidQueue::Job.last

      expect(job.class_name).to eq("ActionMailer::MailDeliveryJob")
      expect(job.arguments["arguments"]).to include("RegistrationsMailer", "verify_email")
    end
  end

  describe ".call with invalid attributes" do
    shared_examples "a rejected registration" do
      it "does not persist a user" do
        expect { register }.not_to(change { User.count })
        expect(register).not_to be_persisted
      end

      it "leaves no audit trail" do
        expect { register }.not_to(change { RecordEvent.count })
      end

      it "sends no mail" do
        expect { register }.not_to(change { SolidQueue::Job.count })
      end

      it "returns the unsaved user carrying the validation errors, so the form can be re-rendered" do
        expect(register.errors).to be_present
      end
    end

    context "when the email is blank" do
      let(:attributes) { valid_attributes.merge(email: "") }

      it_behaves_like "a rejected registration"
    end

    context "when the email is malformed" do
      let(:attributes) { valid_attributes.merge(email: "not-an-email") }

      it_behaves_like "a rejected registration"
    end

    context "when the password is shorter than the ten character minimum" do
      let(:attributes) { valid_attributes.merge(password: "a" * 9) }

      it_behaves_like "a rejected registration"
    end

    context "when the password is missing entirely" do
      let(:attributes) { valid_attributes.except(:password) }

      it_behaves_like "a rejected registration"
    end

    context "when the name is too short" do
      let(:attributes) { valid_attributes.merge(name: "Al") }

      it_behaves_like "a rejected registration"
    end

    context "when the email is already taken" do
      before { FactoryBot.create(:user, email: "andy@example.com") }

      it_behaves_like "a rejected registration"

      it "reports the conflict on the email attribute" do
        expect(register.errors[:email]).to be_present
      end

      it "is case insensitive, because the address is normalised before the uniqueness check" do
        result = described_class.call(attributes: valid_attributes.merge(email: "ANDY@Example.COM"))

        expect(result).not_to be_persisted
        expect(result.errors[:email]).to be_present
      end
    end
  end

  describe ".call when the unique index rejects a concurrent duplicate signup" do
    # Two requests for the same address can both pass the uniqueness validation and race into
    # the INSERT. The database index is the real guard; the service must translate that into a
    # form error rather than a 500.
    before do
      allow_any_instance_of(User).to receive(:save).and_raise(ActiveRecord::RecordNotUnique) # rubocop:disable RSpec/AnyInstance
    end

    it "surfaces the collision as a validation error instead of raising" do
      expect { register }.not_to raise_error
      expect(register).not_to be_persisted
      expect(register.errors[:email]).to be_present
    end

    it "sends no mail" do
      expect { register }.not_to(change { SolidQueue::Job.count })
    end
  end

  describe ".call with attributes a caller is not allowed to set" do
    let(:attributes) do
      valid_attributes.merge(
        role: "admin",
        email_verified_at: 10.years.ago,
        nickname: "sneaky_nickname",
        preferences: { "beta" => true }
      )
    end

    it "ignores everything outside REGISTRABLE_ATTRIBUTES" do
      expect(register).to be_persisted
      expect(register).to have_attributes(
        role: "user",
        email_verified_at: nil,
        nickname: nil,
        preferences: {}
      )
      expect(register).not_to be_admin
    end

    it "also ignores them when they arrive as unpermitted request parameters" do
      params = ActionController::Parameters.new(attributes).permit!

      result = described_class.call(attributes: params)

      expect(result).to be_persisted
      expect(result.role).to eq("user")
    end
  end
end
