class BenchmarkVirtualYid < ApplicationRecord
  self.primary_key = "yid"

  YID_CODE = "bvy".freeze

  belongs_to :team, inverse_of: :benchmark_virtual_yid, foreign_key: "team_yid"

  normalizes :name, with: ->(name) { name.strip }

  validates :name, presence: true
end
