class BenchmarkRailsYid < ApplicationRecordYidEnabled
  YID_CODE = "bry".freeze

  belongs_to :team, inverse_of: :benchmark_rails_yid, foreign_key: "team_yid"

  normalizes :name, with: ->(name) { name.strip }

  validates :name, presence: true
end
