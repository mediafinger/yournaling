# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContentVisibilityPolicy do
  let(:user) { FactoryBot.create(:user) }
  let(:team) { FactoryBot.create(:team) }
  let(:other_team) { FactoryBot.create(:team) }
  let(:member) { Member.create!(team:, user:, roles: member_roles) }
  let(:member_roles) { %w[owner] }
  let(:policy) { described_class.new(record, user:, team:, member:) }

  describe "#update? on Member record" do
    subject(:allowed_to?) { policy.apply(:update?) }

    let(:record) { Member.create!(team:, user: FactoryBot.create(:user), roles: %w[editor]) }

    it "allows owner role" do
      member.roles = %w[owner]

      expect(allowed_to?).to be true
    end

    it "allows manager role" do
      member.roles = %w[manager]

      expect(allowed_to?).to be true
    end

    it "denies editor role" do
      member.roles = %w[editor]

      expect(allowed_to?).to be false
    end

    it "denies publisher role" do
      member.roles = %w[publisher]

      expect(allowed_to?).to be false
    end

    it "denies when member record belongs to another team" do
      other_member = Member.create!(team: other_team, user: FactoryBot.create(:user), roles: %w[editor])
      foreign_policy = described_class.new(other_member, user:, team:, member:)

      expect(foreign_policy.apply(:update?)).to be false
    end
  end

  describe "#update? on Content (Location) record" do
    subject(:allowed_to?) { policy.apply(:update?) }

    let(:record) { FactoryBot.create(:location, team:, visibility:) }

    context "when visibility is 'draft'" do
      let(:visibility) { "draft" }

      it "allows owner, manager, editor, and publisher roles" do
        %w[owner manager editor publisher].each do |role|
          member.roles = [role]

          expect(allowed_to?).to be true
        end
      end
    end

    context "when visibility is 'internal'" do
      let(:visibility) { "internal" }

      it "allows owner, manager, editor, and publisher roles" do
        %w[owner manager editor publisher].each do |role|
          member.roles = [role]

          expect(allowed_to?).to be true
        end
      end
    end

    context "when visibility is 'published'" do
      let(:visibility) { "published" }

      it "allows publisher role" do
        member.roles = %w[publisher]

        expect(allowed_to?).to be true
      end

      it "denies owner, manager, and editor roles without publisher" do
        %w[owner manager editor].each do |role|
          member.roles = [role]

          expect(allowed_to?).to be false
        end
      end
    end

    context "when visibility is 'archived'" do
      let(:visibility) { "archived" }

      it "allows owner, manager, and publisher roles" do
        %w[owner manager publisher].each do |role|
          member.roles = [role]

          expect(allowed_to?).to be true
        end
      end

      it "denies editor role" do
        member.roles = %w[editor]

        expect(allowed_to?).to be false
      end
    end

    context "when visibility is 'blocked'" do
      it "denies all roles on blocked content" do
        blocked_location = FactoryBot.create(:location, team:, visibility: "blocked")
        blocked_policy = described_class.new(blocked_location, user:, team:, member:)

        Member::VALID_ROLES.each do |role|
          member.roles = [role]

          expect(blocked_policy.apply(:update?)).to be false
        end
      end
    end

    context "when content belongs to another team" do
      let(:record) { FactoryBot.create(:location, team: other_team, visibility: "internal") }

      it "returns false even for owner" do
        member.roles = %w[owner]

        expect(allowed_to?).to be false
      end
    end

    context "when unauthenticated or not in team" do
      let(:record) { FactoryBot.create(:location, team:, visibility: "internal") }
      let(:policy) { described_class.new(record, user: FactoryBot.create(:user), team:, member: nil) }

      it "returns false" do
        expect(allowed_to?).to be false
      end
    end
  end
end
