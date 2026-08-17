# frozen_string_literal: true

require "rails_helper"

RSpec.describe Publishing, type: :model do
  let(:team) { FactoryBot.create(:team) }
  let(:chronicle) { FactoryBot.create(:chronicle, team: team, visibility: "internal") }
  let(:memory) { FactoryBot.create(:memory, team: team, visibility: "internal") }

  describe "constants" do
    it "defines YID_CODE as pub" do
      expect(described_class::YID_CODE).to eq("pub")
    end
  end

  describe "associations" do
    it "belongs to a team" do
      publishing = described_class.new(team: team, post: chronicle, first_published_at: Time.current,
        republished_at: Time.current, visibility: "published")
      expect(publishing.team).to eq(team)
    end

    it "belongs to a polymorphic post (Chronicle)" do
      publishing = described_class.new(team: team, post: chronicle, first_published_at: Time.current,
        republished_at: Time.current, visibility: "published")
      expect(publishing.post).to eq(chronicle)
      expect(publishing.post_type).to eq("Chronicle")
      expect(publishing.post_id).to eq(chronicle.id)
    end

    it "belongs to a polymorphic post (Memory)" do
      publishing = described_class.new(team: team, post: memory, first_published_at: Time.current,
        republished_at: Time.current, visibility: "published")
      expect(publishing.post).to eq(memory)
      expect(publishing.post_type).to eq("Memory")
      expect(publishing.post_id).to eq(memory.id)
    end
  end

  describe "validations" do
    it "is valid with valid attributes" do
      publishing = described_class.new(
        team: team,
        post: chronicle,
        first_published_at: Time.current,
        republished_at: Time.current,
        published_count: 1,
        visibility: "published"
      )
      expect(publishing).to be_valid
    end

    it "requires a team" do
      publishing = described_class.new(team: nil)
      publishing.valid?
      expect(publishing.errors[:team]).to be_present
    end

    it "requires a post" do
      publishing = described_class.new(post: nil)
      publishing.valid?
      expect(publishing.errors[:post]).to be_present
    end

    it "requires first_published_at" do
      publishing = described_class.new(first_published_at: nil)
      publishing.valid?
      expect(publishing.errors[:first_published_at]).to be_present
    end

    it "requires republished_at" do
      publishing = described_class.new(republished_at: nil)
      publishing.valid?
      expect(publishing.errors[:republished_at]).to be_present
    end

    it "requires published_count" do
      publishing = described_class.new(published_count: nil)
      publishing.valid?
      expect(publishing.errors[:published_count]).to be_present
    end

    it "enforces uniqueness of post_type and post_id" do
      described_class.create!(
        team: team,
        post: chronicle,
        first_published_at: Time.current,
        republished_at: Time.current,
        published_count: 1,
        visibility: "published"
      )
      duplicate = described_class.new(
        team: team,
        post: chronicle,
        first_published_at: Time.current,
        republished_at: Time.current,
        published_count: 1,
        visibility: "published"
      )
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:post_id]).to be_present
    end
  end

  describe "scopes" do
    let!(:pub1) { FactoryBot.create(:publishing, team: team, visibility: "published", republished_at: 3.hours.ago) }
    let!(:pub2) { FactoryBot.create(:publishing, team: team, visibility: "published", republished_at: 1.hour.ago) }
    let!(:pub3) { FactoryBot.create(:publishing, team: team, visibility: "internal", republished_at: 10.minutes.ago) }
    let!(:pub4) { FactoryBot.create(:publishing, team: team, visibility: "published", republished_at: 2.hours.ago) }

    describe ".published" do
      it "returns only publishings with visibility published" do
        expect(described_class.published).to contain_exactly(pub1, pub2, pub4)
      end
    end

    describe ".feed" do
      it "returns published entries ordered by republished_at DESC and limited to 5" do
        expect(described_class.feed.to_a).to eq([pub2, pub4, pub1])
      end

      it "limits results to 5 entries" do
        4.times do |i|
          FactoryBot.create(:publishing, team: team, visibility: "published", republished_at: (i + 4).hours.ago)
        end
        expect(described_class.feed.count).to eq(5)
      end
    end
  end
end
