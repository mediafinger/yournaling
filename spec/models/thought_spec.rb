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

    it "validates maximum length of text (512 chars)" do
      thought.text = "a" * 513
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
end
