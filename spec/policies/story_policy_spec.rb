# frozen_string_literal: true

RSpec.describe StoryPolicy do
  let(:user) { FactoryBot.create(:user) }
  let(:team) { FactoryBot.create(:team) }
  let(:other_team) { FactoryBot.create(:team) }
  let(:owned_record) { FactoryBot.create(:story, team: team) }
  let(:unassociated_record) { FactoryBot.create(:story, team: other_team) }
  let(:policy_class) { described_class }

  describe "#scope" do
    let(:relation) { Story.unscoped }
    let(:scope_name) { :current_team_scope }

    it_behaves_like "current team scope"
  end

  describe "#read?" do
    let(:rule) { :read? }

    it_behaves_like "guest user"
  end

  describe "#create?" do
    let(:rule) { :create? }
    let(:roles) { %i[owner manager editor] }

    it_behaves_like "current team owns record and member has role"
  end

  describe "#update?" do
    let(:rule) { :update? }
    let(:roles) { %i[owner manager editor] }

    it_behaves_like "current team owns record and member has role"
  end

  describe "#destroy?" do
    let(:rule) { :destroy? }
    let(:roles) { %i[owner manager] }

    it_behaves_like "current team owns record and member has role"
  end
end
