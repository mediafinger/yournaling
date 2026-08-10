# frozen_string_literal: true

RSpec.describe MemoryPolicy do
  let(:user) { FactoryBot.create(:user) }
  let(:team) { FactoryBot.create(:team) }
  let(:other_team) { FactoryBot.create(:team) }
  let(:owned_record) { FactoryBot.create(:memory, team: team) }
  let(:unassociated_record) { FactoryBot.create(:memory, team: other_team, visibility: "internal") }
  let(:policy_class) { described_class }

  describe "#scope" do
    let(:relation) { Memory.unscoped }
    let(:scope_name) { :current_team_scope }

    it_behaves_like "current team scope"
  end

  describe "#read?" do
    subject(:allowed_to?) { policy.apply(:read?) }

    let(:member) { Member.create!(team:, user:, roles: %w[editor]) }
    let(:policy) { described_class.new(record, user:, team:, member:) }

    context "when record is owned by the current team" do
      let(:record) { owned_record }

      it "returns true even if internal" do
        record.update_column(:visibility, "internal")
        expect(allowed_to?).to be true
      end
    end

    context "when record belongs to another team" do
      let(:record) { unassociated_record }

      it "returns true when published" do
        record.update_column(:visibility, "published")
        expect(allowed_to?).to be true
      end

      it "returns false when internal" do
        record.update_column(:visibility, "internal")
        expect(allowed_to?).to be false
      end

      it "returns false when draft" do
        record.update_column(:visibility, "draft")
        expect(allowed_to?).to be false
      end

      it "returns false when archived" do
        record.update_column(:visibility, "archived")
        expect(allowed_to?).to be false
      end
    end
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
