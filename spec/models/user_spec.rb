# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { described_class.new(valid_attributes) }

  let(:valid_attributes) do
    {
      name: "Andy Vanlifer",
      email: "andy.travels@example.com",
      password: "password1234",
      role: "user",
    }
  end

  describe "validations and constraints" do
    it "is valid with valid attributes" do
      expect(user).to be_valid
    end

    it "validates email presence, format, and uniqueness" do
      user.email = "invalid-email"
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("not valid")

      user.email = ""
      expect(user).not_to be_valid

      user.email = valid_attributes[:email]
      user.save!

      duplicate = described_class.new(valid_attributes.merge(email: "ANDY.TRAVELS@example.com"))
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to be_present
    end

    it "validates password length on create" do
      user.password = "short"
      expect(user).not_to be_valid
      expect(user.errors[:password]).to be_present

      user.password = "a" * 73
      expect(user).not_to be_valid

      user.password = "validpassword123"
      expect(user).to be_valid
    end

    # `has_secure_password validations: false` means a missing password is otherwise only caught by
    # the password_digest presence rule, whose message ("Password digest can't be blank") is
    # meaningless to the person filling in the signup form.
    it "reports a missing password against :password, not :password_digest" do
      user.password = nil

      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
      expect(user.errors[:password_digest]).to be_empty
    end

    it "still guards password_digest presence on an existing record" do
      user.save!
      user.password_digest = nil

      expect(user).not_to be_valid
      expect(user.errors[:password_digest]).to be_present
    end

    it "validates name length between 3 and 72 characters" do
      user.name = "Ab"
      expect(user).not_to be_valid
      expect(user.errors[:name]).to be_present

      user.name = "A" * 73
      expect(user).not_to be_valid

      user.name = "Valid Name"
      expect(user).to be_valid
    end

    it "validates nickname length between 7 and 72 characters" do
      user.nickname = "short"
      expect(user).not_to be_valid
      expect(user.errors[:nickname]).to be_present

      user.nickname = "valid_traveler_nick"
      expect(user).to be_valid
    end

    it "validates role inclusion in USER_ROLES" do
      user.role = "superhero"
      expect(user).not_to be_valid
      expect(user.errors[:role]).to be_present

      User::USER_ROLES.each do |role|
        user.role = role
        expect(user).to be_valid
      end
    end
  end

  describe "normalizations" do
    it "strips and downcases email" do
      created_user = described_class.create!(valid_attributes.merge(email: "  ANDY.TRAVELS@EXAMPLE.COM  "))
      expect(created_user.email).to eq("andy.travels@example.com")
    end

    it "strips whitespace from name" do
      created_user = described_class.create!(valid_attributes.merge(name: "   Andy Vanlifer   "))
      expect(created_user.name).to eq("Andy Vanlifer")
    end

    it "parameterizes and underscores nickname" do
      created_user = described_class.create!(valid_attributes.merge(nickname: "Andy Van Life 2026"))
      expect(created_user.nickname).to eq("andy_van_life_2026")
    end
  end

  describe "role predicate methods" do
    User::USER_ROLES.each do |role|
      it "defines #{role}? predicate method correctly" do
        user.role = role
        expect(user.public_send(:"#{role}?")).to be true

        other_roles = User::USER_ROLES - [role]
        other_roles.each do |other_role|
          expect(user.public_send(:"#{other_role}?")).to be false
        end
      end
    end
  end

  describe "email verification" do
    describe "#email_verified?" do
      it "is false while email_verified_at is blank and true once it is set" do
        expect(user.email_verified?).to be false

        user.email_verified_at = Time.current

        expect(user.email_verified?).to be true
      end
    end

    describe "#verify_email!" do
      before { user.save! }

      it "records the moment the address was verified" do
        freeze_time do
          expect { user.verify_email! }.to change { user.reload.email_verified_at }.from(nil).to(Time.current)
        end
      end

      it "is idempotent and keeps the original verification timestamp" do
        user.verify_email!
        original_timestamp = user.reload.email_verified_at

        travel 1.day do
          expect { user.verify_email! }.not_to(change { user.reload.email_verified_at })
        end

        expect(user.reload.email_verified_at).to eq(original_timestamp)
      end
    end

    describe "scopes" do
      it "partitions users into verified and unverified" do
        verified = FactoryBot.create(:user, :email_verified)
        unverified = FactoryBot.create(:user)

        expect(described_class.email_verified).to contain_exactly(verified)
        expect(described_class.email_unverified).to contain_exactly(unverified)
      end
    end

    describe "the :email_verification token" do
      before { user.save! }

      it "round-trips back to the user it was generated for" do
        token = user.generate_token_for(:email_verification)

        expect(described_class.find_by_token_for(:email_verification, token)).to eq(user)
      end

      it "expires after EMAIL_VERIFICATION_TOKEN_VALIDITY" do
        token = user.generate_token_for(:email_verification)

        travel(User::EMAIL_VERIFICATION_TOKEN_VALIDITY - 1.minute) do
          expect(described_class.find_by_token_for(:email_verification, token)).to eq(user)
        end

        travel(User::EMAIL_VERIFICATION_TOKEN_VALIDITY + 1.minute) do
          expect(described_class.find_by_token_for(:email_verification, token)).to be_nil
        end
      end

      it "can only be redeemed once, because verifying rebinds the payload" do
        token = user.generate_token_for(:email_verification)
        user.verify_email!

        expect(described_class.find_by_token_for(:email_verification, token)).to be_nil
      end

      it "is invalidated when the email address changes" do
        token = user.generate_token_for(:email_verification)
        user.update!(email: "moved.on@example.com")

        expect(described_class.find_by_token_for(:email_verification, token)).to be_nil
      end

      it "cannot be substituted by a token generated for another purpose" do
        password_reset_token = user.generate_token_for(:password_reset)

        expect(described_class.find_by_token_for(:email_verification, password_reset_token)).to be_nil
      end

      it "returns nil for malformed input instead of raising" do
        ["", "not-a-token", "a.b.c", SecureRandom.hex(32)].each do |garbage|
          expect(described_class.find_by_token_for(:email_verification, garbage)).to be_nil
        end

        expect(described_class.find_by_token_for(:email_verification, nil)).to be_nil
      end
    end
  end

  describe "associations" do
    it "has many logins, memberships, and teams" do
      user.save!
      team = FactoryBot.create(:team)
      Member.create!(team: team, user: user, roles: %w[owner])

      expect(user.memberships.count).to eq(1)
      expect(user.teams).to include(team)
    end
  end

  describe "token generation" do
    before { user.save! }

    it "generates and finds by password_reset token" do
      token = user.generate_token_for(:password_reset)
      expect(described_class.find_by_token_for(:password_reset, token)).to eq(user)
    end

    it "invalidates password_reset token when password changes" do
      token = user.generate_token_for(:password_reset)
      user.update!(password: "new_password1234")

      expect(described_class.find_by_token_for(:password_reset, token)).to be_nil
    end

    it "generates and finds by email_change token" do
      token = user.generate_token_for(:email_change)
      expect(described_class.find_by_token_for(:email_change, token)).to eq(user)
    end
  end
end
