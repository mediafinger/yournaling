# frozen_string_literal: true

require "rails_helper"

RSpec.describe Story, type: :model do
  subject(:story) {
    FactoryBot.create(:story, team: team, name: "The Alhambra", content: "A long day walking the palace grounds.")
  }

  let(:team) { FactoryBot.create(:team) }

  describe "constants" do
    it "defines YID_CODE as story" do
      expect(described_class::YID_CODE).to eq("story")
    end
  end

  describe "associations" do
    it "belongs to a team" do
      expect(story.team).to eq(team)
    end

    it "has many distinct chronicles through chronicle_entries" do
      chronicle1 = FactoryBot.create(:chronicle, team: team)
      chronicle2 = FactoryBot.create(:chronicle, team: team)

      FactoryBot.create(:chronicle_entry, chronicle: chronicle1, team: team, entry: story, position: 1)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle2, team: team, entry: story, position: 1)

      expect(story.chronicles).to contain_exactly(chronicle1, chronicle2)
    end

    it "destroys associated chronicle_entries when the story is destroyed" do
      chronicle = FactoryBot.create(:chronicle, team: team)
      entry = FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: story)

      expect { story.destroy! }.to change { ChronicleEntry.count }.by(-1)
      expect { entry.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "is not referenced by Memory" do
      expect(described_class.reflect_on_association(:memories)).to be_nil
      expect(story).not_to respond_to(:memories)
    end
  end

  describe "validations and normalizations" do
    it "requires a name" do
      story.name = ""
      expect(story).not_to be_valid
      expect(story.errors[:name]).to be_present
    end

    it "requires content" do
      story.content = ""
      expect(story).not_to be_valid
      expect(story.errors[:content]).to be_present
    end

    it "rejects content shorter than the minimum" do
      story.content = "too short"
      expect(story).not_to be_valid
    end

    it "rejects content longer than 16_384 characters" do
      story.content = "a" * 16_385
      expect(story).not_to be_valid
      expect(story.errors[:content]).to be_present
    end

    it "validates inclusion of visibility in VISIBILITY_STATES" do
      story.visibility = "nonsense"
      expect(story).not_to be_valid
    end

    it "strips leading and trailing whitespace" do
      s = described_class.create!(team: team, name: "  Trim  ", content: "   #{'x' * 30}   ")
      expect(s.name).to eq("Trim")
      expect(s.content).to eq("x" * 30)
    end

    it "prevents changing team_id via readonly attribute" do
      other_team = FactoryBot.create(:team)
      expect { story.update(team_id: other_team.id) }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    end
  end

  describe "#content_html" do
    it "renders the Markdown content to sanitized HTML" do
      story.update!(content: "## Heading\n\nWith a <script>alert(1)</script> and **bold**.")
      expect(story.content_html).to include("<h2").and include("<strong>bold</strong>")
      expect(story.content_html).not_to include("<script>")
    end
  end

  describe "search index" do
    it "creates a PgSearch::Document indexing the name and content" do
      expect { story }.to change { PgSearch::Document.where(searchable_type: "Story").count }.by(1)
      expect(story.pg_search_document.content).to include("Alhambra")
    end
  end

  describe "parent visibility constraints" do
    it "prohibits reducing visibility below a published chronicle" do
      story.update!(visibility: "published")
      chronicle = FactoryBot.create(:chronicle, team: team, name: "Andalusia", visibility: "published")
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: story)

      story.visibility = "internal"
      expect(story).not_to be_valid
      expect(story.errors[:visibility].first).to include("Andalusia")
    end
  end
end
