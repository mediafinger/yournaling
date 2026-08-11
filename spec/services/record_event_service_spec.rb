# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecordEventService, type: :service do
  let(:team) { FactoryBot.create(:team) }
  let(:user) { FactoryBot.create(:user) }
  let(:picture) { FactoryBot.create(:picture, team: team) }

  describe ".call" do
    it "creates an event record for standard team operations" do
      expect {
        described_class.call(
          record: picture,
          team: team,
          user: user,
          name: "created",
          properties: { memo: "Initial snapshot" }
        )
      }.to change { RecordEvent.count }.by(1)

      event = RecordEvent.last
      expect(event.name).to eq("created")
      expect(event.record_type).to eq("pic")
      expect(event.record_id).to eq(picture.id)
      expect(event.team_id).to eq(team.id)
      expect(event.user_id).to eq(user.id)
      expect(event.done_by_admin).to be false
      expect(event.properties).to eq("memo" => "Initial snapshot")
    end

    it "creates an event record marked as done_by_admin" do
      described_class.call(
        record: picture,
        team: team,
        user: user,
        name: "deleted",
        done_by_admin: true
      )

      event = RecordEvent.last
      expect(event.name).to eq("deleted")
      expect(event.done_by_admin).to be true
      expect(event.team_id).to eq("admin")
    end
  end
end
