class ChroniclePicture < ApplicationRecordYidEnabled
  YID_CODE = "cronpic".freeze

  belongs_to :team, inverse_of: :chronicle_pictures, foreign_key: "team_yid"
  belongs_to :chronicle, inverse_of: :chronicle_pictures, foreign_key: "chronicle_yid"
  belongs_to :picture, inverse_of: :chronicle_pictures, foreign_key: "picture_yid"

  attr_readonly :team_yid

  delegate :name, to: :location
end
