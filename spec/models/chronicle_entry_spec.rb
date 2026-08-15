# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChronicleEntry, type: :model do
  subject(:chronicle_entry) { described_class.new(valid_attributes) }

  let(:team) { FactoryBot.create(:team) }
  let(:chronicle) { FactoryBot.create(:chronicle, team: team) }
  let(:thought) { FactoryBot.create(:thought, team: team) }

  let(:valid_attributes) do
    {
      team: team,
      chronicle: chronicle,
      entry: thought,
      position: 1,
    }
  end

  describe "constants" do
    it "defines YID_CODE as crent" do
      expect(described_class::YID_CODE).to eq("crent")
    end

    it "defines VALID_ENTRY_TYPES" do
      expect(described_class::VALID_ENTRY_TYPES).to eq(%w[Memory Picture Location Thought Weblink])
    end
  end

  describe "associations" do
    it "belongs to chronicle and team" do
      expect(chronicle_entry.chronicle).to eq(chronicle)
      expect(chronicle_entry.team).to eq(team)
    end

    it "belongs to entry polymorphically" do
      expect(chronicle_entry.entry).to eq(thought)
      expect(chronicle_entry.entry_type).to eq("Thought")
      expect(chronicle_entry.entry_id).to eq(thought.id)
    end
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(chronicle_entry).to be_valid
    end

    it "validates presence and inclusion of entry_type" do
      chronicle_entry.entry = nil
      chronicle_entry.entry_id = "user_123"
      chronicle_entry.entry_type = "User"
      expect(chronicle_entry).not_to be_valid
      expect(chronicle_entry.errors[:entry_type]).to be_present

      described_class::VALID_ENTRY_TYPES.each do |valid_type|
        chronicle_entry.entry_type = valid_type
        expect(chronicle_entry.errors[:entry_type]).to be_empty if chronicle_entry.valid?
      end
    end

    it "validates presence of entry" do
      chronicle_entry.entry = nil
      chronicle_entry.entry_id = nil
      expect(chronicle_entry).not_to be_valid
      expect(chronicle_entry.errors[:entry]).to be_present
    end

    it "validates that position is a positive integer" do
      [0, -1, 1.5, "abc"].each do |invalid_pos|
        chronicle_entry.position = invalid_pos
        expect(chronicle_entry).not_to be_valid
        expect(chronicle_entry.errors[:position]).to be_present
      end

      [1, 2, 100].each do |valid_pos|
        chronicle_entry.position = valid_pos
        expect(chronicle_entry).to be_valid
      end
    end

    it "allows the same entry to be attached multiple times in different positions" do
      entry1 = described_class.create!(team: team, chronicle: chronicle, entry: thought, position: 1)
      entry2 = described_class.new(team: team, chronicle: chronicle, entry: thought, position: 2)

      expect(entry2).to be_valid
      expect { entry2.save! }.not_to raise_error
      expect(chronicle.reload.chronicle_entries.pluck(:id)).to contain_exactly(entry1.id, entry2.id)
    end

    it "prevents changing team_id via readonly attribute" do
      chronicle_entry.save!
      other_team = FactoryBot.create(:team)
      expect {
        chronicle_entry.update(team_id: other_team.id)
      }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    end

    it "validates that entry belongs to the same team as chronicle" do
      other_team = FactoryBot.create(:team)
      other_thought = FactoryBot.create(:thought, team: other_team)
      chronicle_entry.entry = other_thought

      expect(chronicle_entry).not_to be_valid
      expect(chronicle_entry.errors[:entry]).to include("must belong to the same team as the chronicle")
    end

    it "validates that team_id matches chronicle team_id" do
      other_team = FactoryBot.create(:team)
      chronicle_entry.team = other_team

      expect(chronicle_entry).not_to be_valid
      expect(chronicle_entry.errors[:team_id]).to include("must match the chronicle team")
    end
  end

  describe "positioning" do
    let(:picture1) { FactoryBot.create(:picture, team: team) }
    let(:picture2) { FactoryBot.create(:picture, team: team) }
    let(:picture3) { FactoryBot.create(:picture, team: team) }

    it "orders entries by position" do
      e1 = described_class.create!(team: team, chronicle: chronicle, entry: picture1, position: 1)
      e2 = described_class.create!(team: team, chronicle: chronicle, entry: picture2, position: 2)
      e3 = described_class.create!(team: team, chronicle: chronicle, entry: picture3, position: 3)

      expect(e1.reload.position).to eq(1)
      expect(e2.reload.position).to eq(2)
      expect(e3.reload.position).to eq(3)
    end

    it "reorders entries cleanly when position is updated" do
      e1 = described_class.create!(team: team, chronicle: chronicle, entry: picture1, position: 1)
      e2 = described_class.create!(team: team, chronicle: chronicle, entry: picture2, position: 2)
      e3 = described_class.create!(team: team, chronicle: chronicle, entry: picture3, position: 3)

      e3.update!(position: 1)

      expect(e3.reload.position).to eq(1)
      expect(e1.reload.position).to eq(2)
      expect(e2.reload.position).to eq(3)
    end

    it "adjusts downstream positions when an entry is destroyed" do
      e1 = described_class.create!(team: team, chronicle: chronicle, entry: picture1, position: 1)
      e2 = described_class.create!(team: team, chronicle: chronicle, entry: picture2, position: 2)
      e3 = described_class.create!(team: team, chronicle: chronicle, entry: picture3, position: 3)

      e2.destroy!

      expect(e1.reload.position).to eq(1)
      expect(e3.reload.position).to eq(2)
    end
  end
end
