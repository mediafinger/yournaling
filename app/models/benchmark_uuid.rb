class BenchmarkUuid < ApplicationRecord
  self.primary_key = "yid"

  YID_CODE = "bui".freeze

  belongs_to :team, inverse_of: :benchmark_uuid, foreign_key: "team_yid"

  normalizes :name, with: ->(name) { name.strip }

  validates :name, presence: true
end
