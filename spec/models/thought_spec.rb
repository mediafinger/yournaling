# frozen_string_literal: true

require "rails_helper"

RSpec.describe Thought, type: :model do
  subject(:thought) { FactoryBot.create(:thought, team: team, text: "A deep thought about life") }

  let(:team) { FactoryBot.create(:team) }

  describe "constants" do
    it "defines YID_CODE as thot" do
      expect(described_class::YID_CODE).to eq("thot")
    end
  end

  describe "associations" do
    it "belongs to a team" do
      expect(thought.team).to eq(team)
    end

    it "has many distinct chronicles through chronicle_entries" do
      chronicle1 = FactoryBot.create(:chronicle, team: team)
      chronicle2 = FactoryBot.create(:chronicle, team: team)

      FactoryBot.create(:chronicle_entry, chronicle: chronicle1, team: team, entry: thought, position: 1)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle1, team: team, entry: thought, position: 2)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle2, team: team, entry: thought, position: 1)

      expect(thought.chronicles).to contain_exactly(chronicle1, chronicle2)
    end

    it "destroys associated chronicle_entries when thought is destroyed" do
      chronicle = FactoryBot.create(:chronicle, team: team)
      entry = FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: thought)

      expect { thought.destroy! }.to change { ChronicleEntry.count }.by(-1)
      expect { entry.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "nullifies memory reference when thought is destroyed" do
      memory = FactoryBot.create(:memory, team: team, thought: thought)
      thought.destroy!
      expect(memory.reload.thought_id).to be_nil
    end
  end

  describe "validations and normalizations" do
    it "validates presence of text" do
      thought.text = ""
      expect(thought).not_to be_valid
      expect(thought.errors[:text]).to be_present
    end

    it "validates maximum length of text (1024 chars)" do
      thought.text = "a" * 1025
      expect(thought).not_to be_valid
      expect(thought.errors[:text]).to be_present
    end

    it "validates inclusion of visibility in VISIBILITY_STATES" do
      thought.visibility = "unauthorized"
      expect(thought).not_to be_valid
      expect(thought.errors[:visibility]).to be_present
    end

    it "strips leading and trailing whitespace from text" do
      t = described_class.create!(team: team, text: "   Contemplating the universe   ")
      expect(t.text).to eq("Contemplating the universe")
    end

    it "prevents changing team_id via readonly attribute" do
      other_team = FactoryBot.create(:team)
      expect {
        thought.update(team_id: other_team.id)
      }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    end
  end

  describe "search index" do
    it "creates a PgSearch::Document when saved" do
      expect { thought }.to change { PgSearch::Document.where(searchable_type: "Thought").count }.by(1)
    end

    it "indexes the text in the document content" do
      expect(thought.pg_search_document.content).to include(thought.text)
    end

    it "sets team_id on the document" do
      expect(thought.pg_search_document.team_id).to eq(team.id)
    end

    it "returns the record via the searchable association" do
      expect(thought.pg_search_document.searchable).to eq(thought)
    end
  end

  describe "parent visibility constraints" do
    it "prohibits reducing visibility when thought belongs to a published chronicle" do
      thought.update!(visibility: "published")

      chronicle = FactoryBot.create(:chronicle, team: team, name: "Philosophy 101", visibility: "published")
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: thought)

      thought.visibility = "internal"
      expect(thought).not_to be_valid
      expect(thought.errors[:visibility]).to be_present
      expect(thought.errors[:visibility].first).to include("cannot be limited to 'internal'")
      expect(thought.errors[:visibility].first).to include("Philosophy 101")
    end

    it "prohibits reducing visibility when thought belongs to a published memory" do
      thought.update!(visibility: "published")

      FactoryBot.create(:memory, team: team, memo: "Deep reflection", thought: thought, visibility: "published")

      thought.visibility = "internal"
      expect(thought).not_to be_valid
      expect(thought.errors[:visibility]).to be_present
      expect(thought.errors[:visibility].first).to include("cannot be limited to 'internal'")
      expect(thought.errors[:visibility].first).to include("Deep reflection")
    end
  end
end
