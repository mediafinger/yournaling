# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecordEvent, type: :model do
  subject(:record_event) { described_class.new(valid_attributes) }

  let(:team) { FactoryBot.create(:team) }
  let(:user) { FactoryBot.create(:user) }
  let(:location) { FactoryBot.create(:location, team: team) }

  let(:valid_attributes) do
    {
      name: "created",
      record_type: "loc",
      record_id: location.id,
      team_id: team.id,
      user_id: user.id,
      done_by_admin: false,
    }
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(record_event).to be_valid
    end

    it "validates presence of required fields" do
      %i[name record_type record_id].each do |attr|
        record_event[attr] = nil
        expect(record_event).not_to be_valid
        expect(record_event.errors[attr]).to be_present
        record_event[attr] = valid_attributes[attr]
      end
    end

    it "validates boolean inclusion of done_by_admin" do
      record_event.done_by_admin = nil
      expect(record_event).not_to be_valid
      expect(record_event.errors[:done_by_admin]).to be_present
    end
  end

  describe "immutability (readonly?)" do
    it "is not readonly before creation" do
      expect(record_event).not_to be_readonly
    end

    it "becomes readonly once persisted" do
      record_event.save!
      expect(record_event).to be_readonly
      expect {
        record_event.update(name: "updated")
      }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end

  describe "query helper methods" do
    let!(:saved_event) { described_class.create!(valid_attributes) }
    let!(:other_event) do
      described_class.create!(
        valid_attributes.merge(
          name: "deleted",
          record_type: "pic",
          record_id: "pic_2026-08-07T00:00:00.000000Z_1234567890ab"
        )
      )
    end

    it "finds events for a team record with get_history_for_team_record" do
      results = described_class.get_history_for_team_record(team: team, record: location)
      expect(results).to include(saved_event)
      expect(results).not_to include(other_event)
    end

    it "finds events for team events with get_history_for_team_events" do
      results = described_class.get_history_for_team_events(
        event: "created",
        record_type_id_code: "loc",
        team: team
      )
      expect(results).to include(saved_event)
      expect(results).not_to include(other_event)
    end

    it "finds events for user events with get_history_for_user_events" do
      results = described_class.get_history_for_user_events(
        event: "created",
        record_type_id_code: "loc",
        user: user
      )
      expect(results).to include(saved_event)
      expect(results).not_to include(other_event)
    end
  end
end
