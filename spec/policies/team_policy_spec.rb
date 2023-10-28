# frozen_string_literal: true

RSpec.describe TeamPolicy do
  # the following variables are used by the shared_examples:
  #
  let(:user) { FactoryBot.create(:user) }
  let(:team) { FactoryBot.create(:team) }
  let(:other_team) { FactoryBot.create(:team) }
  let(:owned_record) { team }
  let(:unassociated_record) { other_team }
  let(:policy_class) { described_class }

  describe "#scope" do
    let(:relation) { Team.unscoped }
    let(:scope_name) { :current_team_scope }

    it_behaves_like "current team scope"
  end

  describe "#show?" do
    let(:rule) { :show? }

    it_behaves_like "guest user"
  end

  describe "#index?" do
    let(:rule) { :show? }

    it_behaves_like "current user is logged in"
  end

  describe "#create?" do
    let(:rule) { :create? }
    let(:roles) { %w[owner] }

    it_behaves_like "current user is logged in"
  end

  describe "#update?" do
    let(:rule) { :update? }
    let(:roles) { %w[owner] }

    it_behaves_like "current team owns record and member has role"
  end

  describe "#destroy?" do
    let(:rule) { :destroy? }
    let(:roles) { %w[owner] }

    it_behaves_like "current team owns record and member has role"
  end
end
