# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecordHistoryService, type: :service do
  let(:team) { FactoryBot.create(:team) }
  let(:user) { FactoryBot.create(:user) }
  let(:picture) { FactoryBot.create(:picture, team: team) }

  describe ".call" do
    it "creates an audit record for standard team operations" do
      expect {
        described_class.call(
          record: picture,
          team: team,
          user: user,
          event: :created,
          done_by_admin: false
        )
      }.to change { RecordHistory.count }.by(1)

      history = RecordHistory.last
      expect(history.event).to eq("created")
      expect(history.record_type).to eq("pic")
      expect(history.record_id).to eq(picture.id)
      expect(history.team_id).to eq(team.id)
      expect(history.user_id).to eq(user.id)
      expect(history.done_by_admin).to be false
    end

    it "sets team_id to :admin when done_by_admin is true" do
      expect {
        described_class.call(
          record: user,
          team: nil,
          user: user,
          event: :updated,
          done_by_admin: true
        )
      }.to change { RecordHistory.count }.by(1)

      history = RecordHistory.last
      expect(history.event).to eq("updated")
      expect(history.record_type).to eq("user")
      expect(history.record_id).to eq(user.id)
      expect(history.team_id).to eq("admin")
      expect(history.user_id).to eq(user.id)
      expect(history.done_by_admin).to be true
    end
  end

  describe "integration with ApplicationRecordYidEnabled history lifecycle methods" do
    let(:location) { FactoryBot.build(:location, team: team) }

    it "creates an audit record on create_with_history" do
      expect {
        ApplicationRecordYidEnabled.create_with_history(
          record: location,
          history_params: { team: team, user: user }
        )
      }.to change { RecordHistory.count }.by(1)
        .and change { Location.count }.by(1)

      history = RecordHistory.last
      expect(history.event).to eq("created")
      expect(history.record_type).to eq("loc")
      expect(history.record_id).to eq(location.id)
    end

    it "creates an audit record on update_with_history" do
      location.save!
      location.name = "Updated Trailhead"

      expect {
        ApplicationRecordYidEnabled.update_with_history(
          record: location,
          history_params: { team: team, user: user }
        )
      }.to change { RecordHistory.count }.by(1)

      history = RecordHistory.last
      expect(history.event).to eq("updated")
      expect(history.record_type).to eq("loc")
      expect(history.record_id).to eq(location.id)
    end

    it "creates an audit record and destroys record on destroy_with_history" do
      location.save!
      loc_id = location.id

      expect {
        ApplicationRecordYidEnabled.destroy_with_history(
          record: location,
          history_params: { team: team, user: user }
        )
      }.to change { RecordHistory.count }.by(1)
        .and change { Location.count }.by(-1)

      history = RecordHistory.last
      expect(history.event).to eq("deleted")
      expect(history.record_type).to eq("loc")
      expect(history.record_id).to eq(loc_id)
    end
  end
end
