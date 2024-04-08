class BenchmarkId < ApplicationRecord
  YID_CODE = "bid".freeze

  belongs_to :team, foreign_key: "team_yid"

  normalizes :name, with: ->(name) { name.strip }

  validates :name, presence: true
end
