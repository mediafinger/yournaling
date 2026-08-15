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

  describe "#first_picture" do
    it "returns nil when there are no pictures" do
      chronicle.save!
      expect(chronicle.first_picture).to be_nil
    end

    it "returns the first picture according to entry position" do
      chronicle.save!
      picture1 = FactoryBot.create(:picture, team: team, name: "First Picture")
      picture2 = FactoryBot.create(:picture, team: team, name: "Second Picture")
      thought = FactoryBot.create(:thought, team: team)

      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: thought, position: 1)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: picture1, position: 2)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: picture2, position: 3)

      expect(chronicle.first_picture).to eq(picture1)
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

  describe "#attach_picture" do
    let(:user) { FactoryBot.create(:user) }
    let(:existing_picture) { FactoryBot.create(:picture, team: team, name: "Existing Landscape") }
    let(:uploaded_file) do
      Rack::Test::UploadedFile.new(
        Rails.root.join("spec/support/macbookair_stickered.jpg"),
        "image/jpeg"
      )
    end

    before { chronicle.save! }

    it "attaches an existing picture by picture_id" do
      expect {
        chronicle.attach_picture(picture_id: existing_picture.id, user: user)
      }.to change { chronicle.chronicle_entries.count }.by(1)

      entry = chronicle.chronicle_entries.last
      expect(entry.entry).to eq(existing_picture)
      expect(entry.position).to eq(1)
    end

    it "attaches an uploaded picture file" do
      expect {
        chronicle.attach_picture(picture_file: uploaded_file, picture_name: "Fresh Photo", user: user)
      }.to change { Picture.count }.by(1).and change { chronicle.chronicle_entries.count }.by(1)

      new_pic = Picture.last
      expect(new_pic.name).to eq("Fresh Photo")
      expect(new_pic.team).to eq(team)
      expect(chronicle.chronicle_entries.last.entry).to eq(new_pic)
    end

    it "positions multiple attached pictures sequentially at the end and loads in position order" do
      chronicle.attach_picture(picture_id: existing_picture.id, user: user)
      second_picture = FactoryBot.create(:picture, team: team, name: "Second Photo")
      chronicle.attach_picture(picture_id: second_picture.id, user: user)

      entries = chronicle.reload.chronicle_entries
      expect(entries.map(&:position)).to eq([1, 2])
      expect(entries.map(&:entry)).to eq([existing_picture, second_picture])
    end

    it "orders chronicle_entries by position ASC when loaded via association (regression test)" do
      p1 = FactoryBot.create(:picture, team: team, name: "First Position Picture")
      p2 = FactoryBot.create(:picture, team: team, name: "Second Position Picture")
      # Create entry 2 first, then entry 1 later to verify created_at order does not override position order
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: p2, position: 2)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: p1, position: 1)

      entries = chronicle.reload.chronicle_entries
      expect(entries.map(&:position)).to eq([1, 2])
      expect(entries.map(&:entry)).to eq([p1, p2])
    end

    it "does not attach when picture belongs to another team" do
      other_team = FactoryBot.create(:team)
      other_picture = FactoryBot.create(:picture, team: other_team)

      expect {
        chronicle.attach_picture(picture_id: other_picture.id, user: user)
      }.not_to(change { chronicle.chronicle_entries.count })
    end

    it "does nothing when neither picture_id nor picture_file is provided" do
      expect {
        chronicle.attach_picture(user: user)
      }.not_to(change { chronicle.chronicle_entries.count })
    end
  end

  describe "visibility cascading" do
    let(:team) { FactoryBot.create(:team) }
    let(:chronicle) { FactoryBot.create(:chronicle, team: team, visibility: "internal") }
    let(:picture) { FactoryBot.create(:picture, team: team, visibility: "internal") }
    let(:thought) { FactoryBot.create(:thought, team: team, visibility: "internal") }
    let(:memory) { FactoryBot.create(:memory, team: team, visibility: "internal") }

    before do
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: picture, position: 1)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: thought, position: 2)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: memory, position: 3)
    end

    it "propagates published visibility to all attached entries when chronicle is published" do
      chronicle.update!(visibility: "published")

      expect(picture.reload.visibility).to eq("published")
      expect(thought.reload.visibility).to eq("published")
      expect(memory.reload.visibility).to eq("published")
    end

    it "propagates draft visibility to all attached entries when chronicle is changed to draft" do
      chronicle.update!(visibility: "draft")

      expect(picture.reload.visibility).to eq("draft")
      expect(thought.reload.visibility).to eq("draft")
      expect(memory.reload.visibility).to eq("draft")
    end

    it "aligns entry visibility when attaching an existing entry to a published chronicle" do
      published_chronicle = FactoryBot.create(:chronicle, team: team, visibility: "published")
      internal_picture = FactoryBot.create(:picture, team: team, visibility: "internal")

      published_chronicle.attach_picture(picture_id: internal_picture.id)

      expect(internal_picture.reload.visibility).to eq("published")
    end

    it "gracefully skips lowering visibility of an insight that belongs to another published post" do
      # Chronicle and a separate Memory are both published
      chronicle.update!(visibility: "published")
      FactoryBot.create(:memory, team: team, picture: picture, visibility: "published")

      # Reducing chronicle to internal should update thought and memory, but skip picture because other_memory is published
      expect {
        chronicle.update!(visibility: "internal")
      }.not_to raise_error

      expect(chronicle.reload.visibility).to eq("internal")
      expect(thought.reload.visibility).to eq("internal")
      expect(picture.reload.visibility).to eq("published")
    end
  end
end
