# frozen_string_literal: true

require "rails_helper"

RSpec.describe Memory, type: :model do
  subject(:memory) { described_class.new(valid_attributes) }

  let(:team) { FactoryBot.create(:team) }
  let(:location) { FactoryBot.create(:location, team: team, visibility: "internal") }
  let(:picture) { FactoryBot.create(:picture, team: team, visibility: "internal") }
  let(:thought) { FactoryBot.create(:thought, team: team, visibility: "internal") }
  let(:weblink) { FactoryBot.create(:weblink, team: team, visibility: "internal") }

  let(:valid_attributes) do
    {
      team: team,
      memo: "Exploring the volcanic beaches at sunset",
      location: location,
      picture: picture,
      thought: thought,
      weblink: weblink,
      visibility: "internal",
    }
  end

  describe "validations and normalizations" do
    it "is valid with valid attributes" do
      expect(memory).to be_valid
    end

    it "validates memo presence and length between 4 and 500 characters" do
      memory.memo = "abc"
      expect(memory).not_to be_valid
      expect(memory.errors[:memo]).to be_present

      memory.memo = "a" * 501
      expect(memory).not_to be_valid

      memory.memo = "Valid memo text"
      expect(memory).to be_valid
    end

    it "strips whitespace from memo" do
      created_memory = described_class.create!(valid_attributes.merge(memo: "   Sunset at the beach   "))
      expect(created_memory.memo).to eq("Sunset at the beach")
    end
  end

  describe "visibility cascade callback (update_visibilty_of_insights)" do
    it "cascades published visibility to all attached insights upon save" do
      memory.visibility = "published"
      memory.save!

      expect(location.reload.visibility).to eq("published")
      expect(picture.reload.visibility).to eq("published")
      expect(thought.reload.visibility).to eq("published")
      expect(weblink.reload.visibility).to eq("published")
    end

    it "cascades archived visibility to all attached insights upon save" do
      memory.visibility = "archived"
      memory.save!

      expect(location.reload.visibility).to eq("archived")
      expect(picture.reload.visibility).to eq("archived")
      expect(thought.reload.visibility).to eq("archived")
      expect(weblink.reload.visibility).to eq("archived")
    end

    it "resets removed insight visibility to internal if not used by other memories" do
      memory.visibility = "published"
      memory.save!

      expect(location.reload.visibility).to eq("published")

      # Remove location from memory
      memory.update!(location: nil)

      expect(location.reload.visibility).to eq("internal")
    end

    it "does not reset removed insight visibility if still used by another memory" do
      memory.visibility = "published"
      memory.save!

      other_memory = FactoryBot.create(
        :memory,
        team: team,
        memo: "Second memory at same location",
        location: location,
        visibility: "published"
      )

      # Remove location from first memory
      memory.update!(location: nil)

      # Still published because other_memory references it
      expect(location.reload.visibility).to eq("published")
      expect(other_memory).to be_present
    end
  end

  describe "search index" do
    it "creates a PgSearch::Document when saved" do
      expect { memory.save! }.to change { PgSearch::Document.where(searchable_type: "Memory").count }.by(1)
    end

    it "indexes the memo in the document content" do
      memory.save!
      doc = PgSearch::Document.find_by(searchable_type: "Memory", searchable_id: memory.id)
      expect(doc.content).to include(memory.memo)
    end

    it "sets team_id on the document" do
      memory.save!
      doc = PgSearch::Document.find_by(searchable_type: "Memory", searchable_id: memory.id)
      expect(doc.team_id).to eq(team.id)
    end

    it "returns the record via the searchable association" do
      memory.save!
      doc = PgSearch::Document.find_by(searchable_type: "Memory", searchable_id: memory.id)
      expect(doc.searchable).to eq(memory)
    end
  end
end
