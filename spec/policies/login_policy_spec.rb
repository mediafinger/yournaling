# frozen_string_literal: true

require "rails_helper"

RSpec.describe LoginPolicy, type: :policy do
  let(:team) { FactoryBot.create(:team) }
  let(:user) { FactoryBot.create(:user) }
  let(:other_user) { FactoryBot.create(:user) }
  let(:member) { Member.create!(team: team, user: user, roles: %w[owner]) }
  let(:login) { Login.create!(user: user, ip_address: "127.0.0.1", user_agent: "TestBrowser") }

  describe "index?" do
    it "allows authenticated users" do
      policy = described_class.new(login, user: user, team: team, member: member)
      expect(policy.index?).to be true
    end

    it "denies guest users" do
      policy = described_class.new(login, user: User.new, team: team, member: member)
      expect(policy.index?).to be false
    end
  end

  describe "destroy?" do
    it "allows the user who owns the login record" do
      policy = described_class.new(login, user: user, team: team, member: member)
      expect(policy.destroy?).to be true
    end

    it "denies another user from destroying this login record" do
      other_member = Member.create!(team: team, user: other_user, roles: %w[owner])
      policy = described_class.new(login, user: other_user, team: team, member: other_member)
      expect(policy.destroy?).to be false
    end

    it "denies guest users" do
      policy = described_class.new(login, user: User.new, team: team, member: member)
      expect(policy.destroy?).to be false
    end
  end
end
