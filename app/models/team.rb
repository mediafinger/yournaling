# frozen_string_literal: true

class Team < ApplicationRecordYidEnabled
  YID_CODE = "team"

  has_many :locations, class_name: "Location", inverse_of: :team, dependent: :destroy
  has_many :members, class_name: "Member", inverse_of: :team, dependent: :destroy
  has_many :memories, class_name: "Memory", inverse_of: :team, dependent: :destroy
  has_many :pictures, class_name: "Picture", inverse_of: :team, dependent: :destroy
  has_many :thoughts, class_name: "Thought", inverse_of: :team, dependent: :destroy
  has_many :weblinks, class_name: "Weblink", inverse_of: :team, dependent: :destroy
  has_many :events, class_name: "RecordEvent", inverse_of: :team, dependent: :delete_all

  has_many :users, through: :members

  multisearchable(
    against: %i[name],
    additional_attributes: ->(team) { { team_id: team.id } }
  )

  normalizes :name, with: ->(name) { name.strip }

  validates :name, presence: true, uniqueness: true, length: { minimum: 7, maximum: 72 }
  validates :preferences, presence: true, if: proc { |record| record.preferences.to_s == "" }
end
