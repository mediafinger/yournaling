# This table stores :created, :updated and other events for records owned by teams
#
# It has indices to allow for fast queries, using the get_ methods below
#   t.index ["event", "record_type", "team_id"]
#   t.index ["event", "record_type", "user_id"]
#   t.index ["team_id", "record_type", "record_id"]
# It does neither hold any DB or AR enforced associations to other tables or models
#   nor does it validate the data persisted.
#
# To become more useful an ID to a new "RecordHistoryChanges" table could be added
#   and more detailed information stored in this table. Given the amount of data, it
#   might be sane to remove all Changes older than 30.days or so.
#
class RecordHistory < ApplicationRecord
  validates :done_by_admin, inclusion: [true, false]
  validates :event, presence: true
  validates :record_type, presence: true
  validates :record_id, presence: true
  validates :team_id, presence: true
  validates :user_id, presence: true

  def readonly?
    created_at.present?
  end

  def get_history_for_team_record(team:, record:)
    where(team_id: team.id, record_type: record.class::YID_CODE, record_id: record.id)
  end

  def get_history_for_team_events(event:, record_type_id_code:, team:)
    where(event:, record_type: record_type_id_code, team_id: team.id)
  end

  def get_history_for_user_events(event:, record_type_id_code:, user:)
    where(event:, record_type: record_type_id_code, user_id: user.id)
  end
end
