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

      # A URL segment is attacker-controlled, and Base64.urlsafe_decode64 happily turns plenty of
      # ordinary-looking strings ("new", "edit", anything a crawler appends) into arbitrary bytes.
      # Handing those to the database raises PG::CharacterNotInRepertoire, which this app's
      # ErrorHandler can only report as a 500. An id that cannot denote a record is a 404.
      %w[new edit 12345].each do |segment|
        context "when the URL segment '#{segment}' decodes to something that is not a valid id" do
          it "returns nil from urlsafe_find rather than raising" do
            expect(Location.urlsafe_find(segment)).to be_nil
          end

          it "raises ActiveRecord::RecordNotFound from urlsafe_find!" do
            expect {
              Location.urlsafe_find!(segment)
            }.to raise_error(ActiveRecord::RecordNotFound)
          end

          it "returns nil from urlsafe_fynd rather than raising" do
            expect(described_class.urlsafe_fynd(segment)).to be_nil
          end
        end
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

  describe "event lifecycle methods" do
    let(:user) { FactoryBot.create(:user) }

    it "creates record and emits created event via .create_with_event" do
      new_thought = Thought.new(team: team, text: "A fresh thought")
      expect {
        Thought.create_with_event(record: new_thought, event_params: { team: team, user: user })
      }.to change { Thought.count }.by(1).and change { RecordEvent.count }.by(1)

      event = RecordEvent.last
      expect(event.name).to eq("created")
      expect(event.record_id).to eq(new_thought.id)
    end

    it "updates record and emits updated event via .update_with_event" do
      thought.text = "Updated text"
      expect {
        Thought.update_with_event(record: thought, event_params: { team: team, user: user })
      }.to change { RecordEvent.count }.by(1)

      expect(thought.reload.text).to eq("Updated text")
      expect(RecordEvent.last.name).to eq("updated")
    end

    it "destroys record and emits deleted event via .destroy_with_event" do
      persisted_thought = FactoryBot.create(:thought, team: team)
      expect {
        Thought.destroy_with_event(record: persisted_thought, event_params: { team: team, user: user })
      }.to change { Thought.count }.by(-1).and change { RecordEvent.count }.by(1)

      expect(RecordEvent.last.name).to eq("deleted")
    end
  end
end
