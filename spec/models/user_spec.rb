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
