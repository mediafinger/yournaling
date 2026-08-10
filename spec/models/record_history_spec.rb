# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecordHistory, type: :model do
  subject(:record_history) { described_class.new(valid_attributes) }

  let(:team) { FactoryBot.create(:team) }
  let(:user) { FactoryBot.create(:user) }
  let(:location) { FactoryBot.create(:location, team: team) }

  let(:valid_attributes) do
    {
      event: "created",
      record_type: "loc",
      record_id: location.id,
      team_id: team.id,
      user_id: user.id,
      done_by_admin: false,
    }
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(record_history).to be_valid
    end

    it "validates presence of required fields" do
      %i[event record_type record_id team_id user_id].each do |attr|
        record_history[attr] = nil
        expect(record_history).not_to be_valid
        expect(record_history.errors[attr]).to be_present
        record_history[attr] = valid_attributes[attr]
      end
    end

    it "validates boolean inclusion of done_by_admin" do
      record_history.done_by_admin = nil
      expect(record_history).not_to be_valid
      expect(record_history.errors[:done_by_admin]).to be_present
    end
  end

  describe "immutability (readonly?)" do
    it "is not readonly before creation" do
      expect(record_history).not_to be_readonly
    end

    it "becomes readonly once persisted" do
      record_history.save!
      expect(record_history).to be_readonly
      expect {
        record_history.update(event: "updated")
      }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end

  describe "query helper methods" do
    let!(:saved_history) { described_class.create!(valid_attributes) }
    let!(:other_history) do
      described_class.create!(
        valid_attributes.merge(
          event: "deleted",
          record_type: "pic",
          record_id: "pic_2026-08-07T00:00:00.000000Z_1234567890ab"
        )
      )
    end

    it "finds history for a team record with get_history_for_team_record" do
      results = described_class.get_history_for_team_record(team: team, record: location)
      expect(results).to include(saved_history)
      expect(results).not_to include(other_history)
    end

    it "finds history for team events with get_history_for_team_events" do
      results = described_class.get_history_for_team_events(
        event: "created",
        record_type_id_code: "loc",
        team: team
      )
      expect(results).to include(saved_history)
      expect(results).not_to include(other_history)
    end

    it "finds history for user events with get_history_for_user_events" do
      results = described_class.get_history_for_user_events(
        event: "created",
        record_type_id_code: "loc",
        user: user
      )
      expect(results).to include(saved_history)
      expect(results).not_to include(other_history)
    end
  end
end
