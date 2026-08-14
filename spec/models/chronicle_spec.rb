# frozen_string_literal: true

require "rails_helper"

RSpec.describe Chronicle, type: :model do
  subject(:chronicle) { described_class.new(valid_attributes) }

  let(:team) { FactoryBot.create(:team) }
  let(:valid_attributes) do
    {
      team: team,
      name: "Day 1: Arrival in Malaga",
      notice: "We landed at Malaga airport and picked up our camper van for the trip.",
      start_date: Date.current,
      visibility: "internal",
    }
  end

  describe "constants" do
    it "defines YID_CODE as cron" do
      expect(described_class::YID_CODE).to eq("cron")
    end
  end

  describe "associations" do
    it "belongs to a team" do
      expect(chronicle.team).to eq(team)
    end

    it "destroys associated chronicle_entries when chronicle is destroyed" do
      chronicle.save!
      thought = FactoryBot.create(:thought, team: team)
      entry = FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: thought)

      expect { chronicle.destroy! }.to change { ChronicleEntry.count }.by(-1)
      expect { entry.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "provides polymorphic through associations" do
      chronicle.save!
      picture = FactoryBot.create(:picture, team: team)
      location = FactoryBot.create(:location, team: team)
      thought = FactoryBot.create(:thought, team: team)
      weblink = FactoryBot.create(:weblink, team: team)
      memory = FactoryBot.create(:memory, team: team)

      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: picture, position: 1)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: location, position: 2)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: thought, position: 3)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: weblink, position: 4)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: memory, position: 5)

      expect(chronicle.pictures).to eq([picture])
      expect(chronicle.locations).to eq([location])
      expect(chronicle.thoughts).to eq([thought])
      expect(chronicle.weblinks).to eq([weblink])
      expect(chronicle.memories).to eq([memory])
    end
  end

  describe "validations and normalizations" do
    it "is valid with valid attributes" do
      expect(chronicle).to be_valid
    end

    it "validates presence of name" do
      chronicle.name = ""
      expect(chronicle).not_to be_valid
      expect(chronicle.errors[:name]).to be_present
    end

    it "validates uniqueness of name scoped to team_id" do
      described_class.create!(valid_attributes)
      duplicate = described_class.new(valid_attributes)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to be_present

      other_team = FactoryBot.create(:team)
      other_team_chronicle = described_class.new(valid_attributes.merge(team: other_team))
      expect(other_team_chronicle).to be_valid
    end

    it "validates presence and length of notice (20..4096 chars)" do
      chronicle.notice = "Short notice"
      expect(chronicle).not_to be_valid
      expect(chronicle.errors[:notice]).to be_present

      chronicle.notice = "a" * 4097
      expect(chronicle).not_to be_valid
      expect(chronicle.errors[:notice]).to be_present

      chronicle.notice = "a" * 20
      expect(chronicle).to be_valid
    end

    it "validates presence of start_date" do
      chronicle.start_date = nil
      expect(chronicle).not_to be_valid
      expect(chronicle.errors[:start_date]).to be_present
    end

    it "validates that end_date is on or after start_date" do
      chronicle.start_date = Date.current
      chronicle.end_date = Date.current - 1.day
      expect(chronicle).not_to be_valid
      expect(chronicle.errors[:end_date]).to be_present

      chronicle.end_date = Date.current
      expect(chronicle).to be_valid

      chronicle.end_date = Date.current + 3.days
      expect(chronicle).to be_valid
    end

    it "validates inclusion of visibility in VISIBILITY_STATES" do
      chronicle.visibility = "unknown"
      expect(chronicle).not_to be_valid
      expect(chronicle.errors[:visibility]).to be_present
    end

    it "normalizes name and notice by stripping whitespace" do
      created = described_class.create!(valid_attributes.merge(
        name: "   Granada Roadtrip   ",
        notice: "   Exploring the Alhambra palaces today.   "
      ))
      expect(created.name).to eq("Granada Roadtrip")
      expect(created.notice).to eq("Exploring the Alhambra palaces today.")
    end

    it "prevents changing team_id via readonly attribute" do
      chronicle.save!
      other_team = FactoryBot.create(:team)
      expect {
        chronicle.update(team_id: other_team.id)
      }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    end
  end

  describe "search index" do
    it "creates a PgSearch::Document when saved" do
      expect { chronicle.save! }.to change { PgSearch::Document.where(searchable_type: "Chronicle").count }.by(1)
    end

    it "indexes the name and notice in the document content" do
      chronicle.save!
      doc = PgSearch::Document.find_by(searchable_type: "Chronicle", searchable_id: chronicle.id)
      expect(doc.content).to include(chronicle.name)
      expect(doc.content).to include(chronicle.notice)
    end

    it "sets team_id on the document" do
      chronicle.save!
      doc = PgSearch::Document.find_by(searchable_type: "Chronicle", searchable_id: chronicle.id)
      expect(doc.team_id).to eq(team.id)
    end

    it "returns the record via the searchable association" do
      chronicle.save!
      doc = PgSearch::Document.find_by(searchable_type: "Chronicle", searchable_id: chronicle.id)
      expect(doc.searchable).to eq(chronicle)
    end
  end
end
