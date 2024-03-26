class ChroniclePicture < ApplicationRecordYidEnabled
  YID_CODE = "cronpic".freeze

  belongs_to :team, inverse_of: :chronicle_pictures, foreign_key: "team_yid"
  belongs_to :chronicle, inverse_of: :chronicle_pictures, foreign_key: "chronicle_yid"
  belongs_to :picture, inverse_of: :chronicle_pictures, foreign_key: "picture_yid"

  attr_readonly :team_yid

  after_commit :update_chronicle

  delegate :name, to: :location

  private

  def update_chronicle
    chronicle.save # to ensure chronicle.pictures_order is being updated
  end
end
