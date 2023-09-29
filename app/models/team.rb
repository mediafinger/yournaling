class Team < ApplicationRecordYidEnabled
  YID_CODE = "team".freeze

  has_many :members, class_name: "Member", foreign_key: "team_yid", inverse_of: :team, dependent: :destroy
  has_many :users, through: :members

  validates :name, presence: true, uniqueness: true, length: { maximum: 72 }
  validates :preferences, presence: true, if: proc { |record| record.preferences.to_s == "" }
end
