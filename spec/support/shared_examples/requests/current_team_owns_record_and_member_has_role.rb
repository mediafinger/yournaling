# frozen_string_literal: true

RSpec.shared_examples_for "current team owns record and member has role" do
  # expects the following variables to be defined in the calling spec:
  # (let() and values only examples!)
  #
  # let(:user) { create(:user) }
  # let(:team) { create(:team) }
  # let(:owned_record) { create(:picture, team: team }
  # let(:unassociated_record) { create(:picture }
  # let(:policy_class) { described_class }
  # let(:rule) { read? }
  # let(:roles) { %w[owner manager editor] } # only 1 role is used (roles.sample) each run, ensure all grant permission
  #

  # current_team_owns_record? && with_role?(:owner, :manager, :editor)
  #
  describe "#rule" do
    subject(:allowed_to?) { policy.apply(rule) }

    let(:policy) { policy_class.new(record, user: user, team: team, member: member) }
    let(:unauthorized_roles) { Member::VALID_ROLES - Array(roles).map(&:to_s) }

    describe "when the record is not owned by the current team" do
      let(:record) { unassociated_record }

      context "when the user is member of the team" do
        let(:member) { Member.create!(team:, user:, roles: unauthorized_roles) }

        it "returns false" do
          expect(allowed_to?).to be false
        end
      end
    end

    describe "when the record is owned by the current team" do
      let(:record) { owned_record }

      context "when the user is not a member of the team" do
        let(:member) { FactoryBot.create(:member) }

        it "returns false" do
          expect(allowed_to?).to be false
        end
      end

      context "when the user is member of the team" do
        let(:member) { Member.create!(team:, user:, roles: unauthorized_roles) }

        it "returns false" do
          expect(allowed_to?).to be false
        end
      end

      context "when the user is member of the team and has the require role" do
        let(:record) { owned_record }

        let(:member) { Member.create!(team:, user:, roles: Array(roles.sample)) } # uses only one role in each run!

        it "returns true" do
          expect(allowed_to?).to be true
        end
      end
    end
  end
end
