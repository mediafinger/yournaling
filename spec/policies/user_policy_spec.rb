# frozen_string_literal: true

RSpec.describe UserPolicy do
  # the following variables are used by the shared_examples:
  #
  let(:user) { FactoryBot.create(:user) }
  let(:team) { FactoryBot.create(:team) }
  let(:other_user) { FactoryBot.create(:user) }
  let(:owned_record) { user }
  let(:unassociated_record) { other_user }
  let(:policy_class) { described_class }

  describe "#scope" do
    let(:relation) { User.unscoped }
    let(:scope_name) { :current_team_scope }

    it_behaves_like "current team scope"
  end

  describe "#read?" do
    let(:rule) { :show? }

    it_behaves_like "guest user"
  end

  describe "#create?" do
    let(:rule) { :create? }

    it_behaves_like "guest user"
  end

  describe "#update?" do
    subject(:allowed_to?) { policy.apply(rule) }

    let(:policy) { policy_class.new(record, user: user, team: nil, member: nil) }
    let(:rule) { :update? }

    context "when the user is the current_user" do
      let(:record) { owned_record }

      it "returns true" do
        expect(allowed_to?).to be true
      end
    end

    context "when the user is not the current_user" do
      let(:record) { unassociated_record }

      it "returns false" do
        expect(allowed_to?).to be false
      end
    end
  end

  describe "#destroy?" do
    subject(:allowed_to?) { policy.apply(rule) }

    let(:policy) { policy_class.new(record, user: user, team: nil, member: nil) }
    let(:rule) { :destroy? }

    context "when the user is the current_user" do
      let(:record) { owned_record }

      it "returns true" do
        expect(allowed_to?).to be true
      end
    end

    context "when the user is not the current_user" do
      let(:record) { unassociated_record }

      it "returns false" do
        expect(allowed_to?).to be false
      end
    end
  end
end
