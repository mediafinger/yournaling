# This table stores :created, :updated and other events for records owned by teams
#
# It has indices to allow for fast queries, using the get_ methods below
#   t.index ["event", "record_type", "team_yid"]
#   t.index ["event", "record_type", "user_yid"]
#   t.index ["team_yid", "record_type", "record_yid"]
# It does neither hold any DB or AR enforced associations to other tables or models
#   nor does it validate the data persisted.
#
# To become more useful an ID to a new "RecordEventChanges" table could be added
#   and more detailed information stored in this table. Given the amount of data, it
#   might be sane to remove all Changes older than 30.days or so.
#
class RecordEvent < ApplicationRecord
  include Ahoy::QueryMethods

  self.table_name = "record_events"

  belongs_to :team, foreign_key: "team_yid", inverse_of: :events
  belongs_to :user, foreign_key: "user_yid", inverse_of: :events
  belongs_to :visit

  validates :done_by_admin, inclusion: [true, false]
  validates :event, presence: true
  validates :record_type, presence: true # should this be optional to track page viewing or similar?
  validates :record_yid, presence: true # should this be optional to track page viewing or similar?
  validates :team_yid, presence: true # should this be optional to track actions unrelated to a team?
  validates :user_yid, presence: true

  def readonly?
    created_at.present?
  end

  def get_events_for_team_record(team:, record:)
    where(team_yid: team.yid, record_type: record.class::YID_CODE, record_yid: record.yid)
  end

  def get_events_for_team_events(name:, record_type_yid_code:, team:)
    where(name:, record_type: record_type_yid_code, team_yid: team.yid)
  end

  def get_events_for_user_events(name:, record_type_yid_code:, user:)
    where(name:, record_type: record_type_yid_code, user_yid: user.yid)
  end
end
