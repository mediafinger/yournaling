# frozen_string_literal: true

require "rails_helper"

RSpec.describe InsightPolicy, type: :policy do
  let(:team) { FactoryBot.create(:team) }
  let(:other_team) { FactoryBot.create(:team) }
  let(:user) { FactoryBot.create(:user) }
  let(:thought) { FactoryBot.create(:thought, team: team) }

  context "when user is a team owner or manager" do
    let!(:member) { Member.create!(team: team, user: user, roles: %w[owner]) }

    it "permits create, update, and destroy on team records" do
      policy = described_class.new(thought, user: user, team: team, member: member)
      expect(policy.read?).to be true
      expect(policy.create?).to be true
      expect(policy.update?).to be true
      expect(policy.destroy?).to be true
    end

    it "denies create, update, and destroy on another team's records" do
      policy = described_class.new(thought, user: user, team: other_team, member: member)
      expect(policy.create?).to be false
      expect(policy.update?).to be false
      expect(policy.destroy?).to be false
    end
  end

  context "when user is a team editor" do
    let!(:member) { Member.create!(team: team, user: user, roles: %w[editor]) }

    it "permits create and update, but denies destroy" do
      policy = described_class.new(thought, user: user, team: team, member: member)
      expect(policy.create?).to be true
      expect(policy.update?).to be true
      expect(policy.destroy?).to be false
    end
  end

  context "when user is a team publisher" do
    let!(:member) { Member.create!(team: team, user: user, roles: %w[publisher]) }

    it "denies create, update, and destroy" do
      policy = described_class.new(thought, user: user, team: team, member: member)
      expect(policy.create?).to be false
      expect(policy.update?).to be false
      expect(policy.destroy?).to be false
    end
  end
end
