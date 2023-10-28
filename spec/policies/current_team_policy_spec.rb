# frozen_string_literal: true

RSpec.describe CurrentTeamPolicy do
  # the following variables are used by the shared_examples:
  #
  let(:user) { FactoryBot.create(:user) }
  let(:team) { FactoryBot.create(:team) }
  let(:other_team) { FactoryBot.create(:team) }
  let(:owned_record) { FactoryBot.create(:member, team: team, user: user) }
  let(:unassociated_record) { FactoryBot.create(:member, team: other_team, user: user) }
  let(:policy_class) { described_class }

  describe "#index?" do
    let(:rule) { :index? }

    it_behaves_like "current user is logged in"
  end

  describe "#show?" do
    subject(:allowed_to?) { policy.apply(rule) }

    let(:policy) { policy_class.new(record, user: user, team: team, member: member) }
    let(:rule) { :show? }

    context "when the user is not a member of the team" do
      let(:record) { unassociated_record }
      let(:member) { unassociated_record }

      it "returns false" do
        expect(allowed_to?).to be false
      end
    end

    context "when the user is member of the team" do
      let(:record) { owned_record }
      let(:member) { owned_record }

      it "returns true" do
        expect(allowed_to?).to be true
      end
    end
  end

  describe "#create?" do
    subject(:allowed_to?) { policy.apply(rule) }

    let(:policy) { policy_class.new(record, user: user, team: team, member: member) }
    let(:rule) { :create? }

    context "when the user is not a member of the team" do
      let(:record) { unassociated_record }
      let(:member) { unassociated_record }

      it "returns false" do
        expect(allowed_to?).to be false
      end
    end

    context "when the user is member of the team" do
      let(:record) { owned_record }
      let(:member) { owned_record }

      it "returns true" do
        expect(allowed_to?).to be true
      end
    end
  end

  describe "#destroy?" do
    subject(:allowed_to?) { policy.apply(rule) }

    let(:policy) { policy_class.new(record, user: user, team: team, member: member) }
    let(:rule) { :destroy? }

    context "when the user is not a member of the team" do
      let(:record) { unassociated_record }
      let(:member) { unassociated_record }

      it "returns false" do
        expect(allowed_to?).to be false
      end
    end

    context "when the user is member of the team" do
      let(:record) { owned_record }
      let(:member) { owned_record }

      it "returns true" do
        expect(allowed_to?).to be true
      end
    end
  end
end
