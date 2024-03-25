class Team < ApplicationRecordYidEnabled
  YID_CODE = "team".freeze

  has_many :chronicles, class_name: "Chronicle", foreign_key: "team_yid", primary_key: "yid", inverse_of: :team,
    dependent: :destroy
  has_many :chronicle_locations, class_name: "ChronicleLocation", foreign_key: "team_yid", primary_key: "yid",
    inverse_of: :team, dependent: :delete_all
  has_many :chronicle_pictures, class_name: "ChroniclePicture", foreign_key: "team_yid", primary_key: "yid",
    inverse_of: :team, dependent: :delete_all
  has_many :chronicle_weblinks, class_name: "ChronicleWeblink", foreign_key: "team_yid", primary_key: "yid",
    inverse_of: :team, dependent: :delete_all
  has_many :locations, class_name: "Location", foreign_key: "team_yid", primary_key: "yid", inverse_of: :team,
    dependent: :destroy
  has_many :members, class_name: "Member", foreign_key: "team_yid", primary_key: "yid", inverse_of: :team,
    dependent: :destroy
  has_many :memories, class_name: "Memory", foreign_key: "team_yid", primary_key: "yid", inverse_of: :team,
    dependent: :destroy
  has_many :pictures, class_name: "Picture", foreign_key: "team_yid", primary_key: "yid", inverse_of: :team,
    dependent: :destroy
  has_many :weblinks, class_name: "Weblink", foreign_key: "team_yid", primary_key: "yid", inverse_of: :team,
    dependent: :destroy

  has_many :users, through: :members

  normalizes :name, with: ->(name) { name.strip }

  validates :name, presence: true, uniqueness: true, length: { minimum: 7, maximum: 72 }
  validates :preferences, presence: true, if: proc { |record| record.preferences.to_s == "" }
end
