# frozen_string_literal: true

require "rails_helper"

# Regression net for the RecordEvent mechanism: every team-owned record that is
# rendered as a card must emit a `created` / `updated` / `deleted` RecordEvent
# through the `*_with_event` helpers on ApplicationRecordYidEnabled. The manage
# card footer reads the `created` event to show who created the record, so a
# silent regression here would blank that out.
RSpec.describe "RecordEvent coverage", type: :model do
  let(:team) { FactoryBot.create(:team) }
  let(:user) { FactoryBot.create(:user) }
  let(:event_params) { { team: team, user: user } }

  # factory => attribute changed on update
  {
    chronicle: :name,
    memory: :memo,
    story: :name,
    thought: :text,
    location: :description,
    weblink: :name,
    picture: :name,
    member: :roles,
  }.each do |factory, change_attr|
    context factory.to_s.camelize do
      let(:model) { factory.to_s.camelize.constantize }

      it "emits a created RecordEvent with the acting user" do
        record = FactoryBot.build(factory, team: team)

        expect {
          model.create_with_event(record: record, event_params: event_params)
        }.to change { RecordEvent.count }.by(1)

        expect(record).to be_persisted
        expect(RecordEvent.order(:created_at).last).to have_attributes(
          name: "created",
          record_type: model::YID_CODE,
          record_id: record.id,
          user_id: user.id,
        )
      end

      it "emits an updated RecordEvent" do
        record = FactoryBot.create(factory, team: team)
        new_value = change_attr == :roles ? %w[manager] : "changed #{SecureRandom.hex(4)}"
        record.assign_attributes(change_attr => new_value)

        expect {
          model.update_with_event(record: record, event_params: event_params)
        }.to change { RecordEvent.where(name: "updated").count }.by(1)

        expect(RecordEvent.where(name: "updated").order(:created_at).last.record_type).to eq(model::YID_CODE)
      end

      it "emits a deleted RecordEvent" do
        record = FactoryBot.create(factory, team: team)

        expect {
          model.destroy_with_event(record: record, event_params: event_params)
        }.to change { RecordEvent.where(name: "deleted").count }.by(1)

        expect(RecordEvent.where(name: "deleted").order(:created_at).last.record_type).to eq(model::YID_CODE)
      end
    end
  end
end
