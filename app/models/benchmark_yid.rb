class BenchmarkYid < ApplicationRecordYidEnabled
  YID_CODE = "byd".freeze

  belongs_to :team, foreign_key: "team_yid"

  normalizes :name, with: ->(name) { name.strip }

  validates :name, presence: true
end
