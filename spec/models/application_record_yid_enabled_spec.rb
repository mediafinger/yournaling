# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationRecordYidEnabled, type: :model do
  let(:team) { FactoryBot.create(:team) }
  let(:location) { FactoryBot.create(:location, team: team) }
  let(:thought) { FactoryBot.create(:thought, team: team) }

  describe "YID generation and formatting" do
    it "generates an ID matching prefix_timestamp_hex format on creation" do
      expect(location.id).to match(/^loc_\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}Z_[a-f0-9]{12}$/)
      expect(team.id).to match(/^team_\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}Z_[a-f0-9]{12}$/)
      expect(thought.id).to match(/^thot_\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}Z_[a-f0-9]{12}$/)
    end

    it "encodes id into URL-safe Base64 without padding for urlsafe_id" do
      encoded = location.urlsafe_id
      expect(encoded).not_to include("=")
      expect(Base64.urlsafe_decode64(encoded)).to eq(location.id)
    end

    it "returns urlsafe_id for to_param" do
      expect(location.to_param).to eq(location.urlsafe_id)
    end
  end

  describe "finder methods" do
    describe ".fynd" do
      it "polymorphically finds any YID-enabled record by its plain-text YID" do
        found_loc = described_class.fynd(location.id)
        expect(found_loc).to eq(location)

        found_thought = described_class.fynd(thought.id)
        expect(found_thought).to eq(thought)
      end

      it "returns nil for non-existent record" do
        expect(described_class.fynd("loc_2026-01-01T00:00:00.000000Z_0123456789ab")).to be_nil
      end
    end

    describe ".urlsafe_fynd" do
      it "polymorphically finds any record by its Base64 encoded urlsafe_id" do
        found = described_class.urlsafe_fynd(location.urlsafe_id)
        expect(found).to eq(location)
      end
    end

    describe ".urlsafe_find and .urlsafe_find!" do
      it "finds a specific model instance by urlsafe_id" do
        expect(Location.urlsafe_find(location.urlsafe_id)).to eq(location)
      end

      it "raises ActiveRecord::RecordNotFound in urlsafe_find! when not found" do
        invalid_urlsafe_id = Base64.urlsafe_encode64("loc_2026-01-01T00:00:00.000000Z_000000000000", padding: false)
        expect {
          Location.urlsafe_find!(invalid_urlsafe_id)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "model registration and discovery" do
    it "maps YID codes to their respective model classes in id_code_models" do
      mapping = described_class.id_code_models
      expect(mapping["loc"]).to eq(Location)
      expect(mapping["pic"]).to eq(Picture)
      expect(mapping["memo"]).to eq(Memory)
      expect(mapping["thot"]).to eq(Thought)
      expect(mapping["link"]).to eq(Weblink)
      expect(mapping["team"]).to eq(Team)
      expect(mapping["user"]).to eq(User)
      expect(mapping["member"]).to eq(Member)
    end
  end
end
