# TODO: not used yet, as PG migration not working
#
class BenchmarkVirtualYid < ApplicationRecord
  self.primary_key = "yid"

  YID_CODE = "bvy".freeze

  belongs_to :team, foreign_key: "team_yid"

  normalizes :name, with: ->(name) { name.strip }

  validates :name, presence: true
end
