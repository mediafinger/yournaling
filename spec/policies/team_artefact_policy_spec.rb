# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeamArtefactPolicy do
  let(:user) { FactoryBot.create(:user) }
  let(:team) { FactoryBot.create(:team) }
  let(:other_team) { FactoryBot.create(:team) }
  let!(:member) { Member.create!(team: team, user: user, roles: member_roles) }
  let(:member_roles) { %w[owner] }
  let(:policy) { described_class.new(TeamArtefact, user: user, team: team, member: member) }

  let!(:draft_item) { FactoryBot.create(:chronicle, team: team, name: "Draft Item", visibility: "draft") }
  let!(:internal_item) { FactoryBot.create(:chronicle, team: team, name: "Internal Item", visibility: "internal") }
  let!(:published_item) { FactoryBot.create(:chronicle, team: team, name: "Published Item", visibility: "published") }
  let!(:archived_item) { FactoryBot.create(:chronicle, team: team, name: "Archived Item", visibility: "archived") }
  let!(:other_team_item) {
    FactoryBot.create(:chronicle, team: other_team, name: "Other Team Item", visibility: "published")
  }

  describe "relation scope" do
    subject(:scoped_artefacts) { policy.apply_scope(TeamArtefact.all, type: :relation).pluck(:artefact_id) }

    context "when member is owner or manager" do
      let(:member_roles) { %w[owner] }

      it "includes all visibility states for the team" do
        expect(scoped_artefacts).to include(draft_item.id, internal_item.id, published_item.id, archived_item.id)
        expect(scoped_artefacts).not_to include(other_team_item.id)
      end
    end

    context "when member is editor" do
      let(:member_roles) { %w[editor] }

      it "includes draft, internal, and published but excludes archived" do
        expect(scoped_artefacts).to include(draft_item.id, internal_item.id, published_item.id)
        expect(scoped_artefacts).not_to include(archived_item.id)
        expect(scoped_artefacts).not_to include(other_team_item.id)
      end
    end

    context "when member is publisher" do
      let(:member_roles) { %w[publisher] }

      it "includes internal, published, and archived but excludes draft" do
        expect(scoped_artefacts).to include(internal_item.id, published_item.id, archived_item.id)
        expect(scoped_artefacts).not_to include(draft_item.id)
        expect(scoped_artefacts).not_to include(other_team_item.id)
      end
    end

    context "when member is both editor and publisher" do
      let(:member_roles) { %w[editor publisher] }

      it "includes the union of allowed visibilities (draft, internal, published, archived)" do
        expect(scoped_artefacts).to include(draft_item.id, internal_item.id, published_item.id, archived_item.id)
        expect(scoped_artefacts).not_to include(other_team_item.id)
      end
    end
  end
end
