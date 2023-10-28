# frozen_string_literal: true

RSpec.describe MemberPolicy do
  # the following variables are used by the shared_examples:
  #
  let(:user) { FactoryBot.create(:user) }
  let(:team) { FactoryBot.create(:team) }
  let(:owned_record) { FactoryBot.create(:member, team:, roles: []) }
  let(:unassociated_record) { FactoryBot.create(:member) }
  let(:policy_class) { described_class }

  describe "#scope" do
    let(:relation) { Member.unscoped }
    let(:scope_name) { :current_team_scope }

    it_behaves_like "current team scope"
  end

  describe "#show?" do
    let(:rule) { :show? }

    it_behaves_like "current user is logged in"
  end

  describe "#create?" do
    let(:rule) { :create? }
    let(:roles) { %i[owner] }

    it_behaves_like "current team owns record and member has role"
  end

  describe "#update?" do
    let(:rule) { :update? }
    let(:roles) { %i[owner] }

    it_behaves_like "current team owns record and member has role"
  end

  describe "#destroy?" do
    context "when the record is any user" do
      let(:rule) { :destroy? }
      let(:roles) { %i[owner] }

      it_behaves_like "current team owns record and member has role"
    end

    context "when the record is the current_user they can end their membership without being team owner" do
      subject(:allowed_to?) { policy.apply(rule) }

      let(:policy) { policy_class.new(record, user: user, team: team, member: member) }
      let(:rule) { :destroy? }
      let(:roles) { [] }
      let(:record) { FactoryBot.create(:member, team:, user:, roles: roles) }
      let(:member) { record }

      it "returns true" do
        expect(allowed_to?).to be true
      end
    end
  end
end
