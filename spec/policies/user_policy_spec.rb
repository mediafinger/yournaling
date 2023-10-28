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
    let(:rule) { :update? }

    it_behaves_like "current team owns record"
  end

  describe "#destroy?" do
    let(:rule) { :destroy? }

    it_behaves_like "current team owns record"
  end
end
