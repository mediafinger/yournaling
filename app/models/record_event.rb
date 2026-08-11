# frozen_string_literal: true

# This table stores :created, :updated and other events for records owned by teams
#
# It has indices to allow for fast queries, using the get_ methods below
#   t.index ["name", "record_type", "team_id"]
#   t.index ["name", "record_type", "user_id"]
#   t.index ["team_id", "record_type", "record_id"]
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

  belongs_to :team, inverse_of: :events, optional: true
  belongs_to :user, inverse_of: :events, optional: true
  belongs_to :visit, class_name: "Ahoy::Visit", inverse_of: :events, optional: true

  validates :done_by_admin, inclusion: [true, false]
  validates :name, presence: true
  validates :record_type, presence: true # should this be optional to track page viewing or similar?
  validates :record_id, presence: true # should this be optional to track page viewing or similar?

  def readonly?
    created_at.present?
  end

  class << self
    def get_history_for_team_record(team:, record:)
      where(team_id: team.id, record_type: record.class::YID_CODE, record_id: record.id)
    end

    def get_history_for_team_events(event:, record_type_id_code:, team:)
      where(name: event, record_type: record_type_id_code, team_id: team.id)
    end

    def get_history_for_user_events(event:, record_type_id_code:, user:)
      where(name: event, record_type: record_type_id_code, user_id: user.id)
    end
  end
end
