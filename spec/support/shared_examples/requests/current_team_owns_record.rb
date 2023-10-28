# frozen_string_literal: true

RSpec.shared_examples_for "current team owns record" do
  # expects the following variables to be defined in the calling spec:
  # (let() and values only examples!)
  #
  # let(:user) { create(:user) }
  # let(:team) { create(:team) }
  # let(:owned_record) { create(:picture, team: team }
  # let(:unassociated_record) { create(:picture }
  # let(:policy_class) { described_class }
  # let(:rule) { read? }
  #

  # current_team_owns_record?
  #
  describe "#rule" do
    subject(:allowed_to?) { policy.apply(rule) }

    let(:policy) { policy_class.new(record, user: user, team: team, member: member) }
    let(:member) { Member.create!(team: FactoryBot.create(:team), user: user, roles: []) }

    describe "when the record is not owned by the team" do
      let(:record) { unassociated_record }

      context "when the user is not a member of the team" do
        it "returns false" do
          expect(allowed_to?).to be false
        end
      end

      context "when the user is member of the team" do
        let(:member) { Member.create!(team:, user:, roles: []) }

        it "returns false" do
          expect(allowed_to?).to be false
        end
      end
    end

    describe "when the record is owned by the team" do
      let(:record) { owned_record }

      context "when the user is not a member of the team" do
        it "returns false" do
          expect(allowed_to?).to be false
        end
      end

      context "when the user is member of the team" do
        let(:member) { Member.create!(team:, user:, roles: []) }

        it "returns true" do
          expect(allowed_to?).to be true
        end
      end
    end
  end
end
