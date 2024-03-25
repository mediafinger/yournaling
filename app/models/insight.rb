# NOTE: pictures, locations, weblinks are insights for chronicles
#
class Insight < ApplicationRecordYidEnabled
  YID_CODE = "ins".freeze

  belongs_to :team, inverse_of: :insights, foreign_key: "team_yid"
  belongs_to :chronicle, inverse_of: :insights, foreign_key: "chronicle_yid"
  belongs_to :location, inverse_of: :insights, foreign_key: "location_yid", optional: true
  belongs_to :picture, inverse_of: :insights, foreign_key: "picture_yid", optional: true
  belongs_to :weblink, inverse_of: :insights, foreign_key: "weblink_yid", optional: true

  attr_readonly :team_yid

  validate :exactly_one_insight

  private

  # this is a rather artifical limitation, given chronicles can have many insights
  # it might make thinks easier, or it might not be needed at all and could be refactored
  def exactly_one_insight
    return true if location.present? && !picture.present? && !weblink.present?
    return true if picture.present? && !location.present? && !weblink.present?
    return true if weblink.present? && !location.present? && !picture.present?

    errors.add(:base, "Only one of Location, Picture, Weblink may be added")
  end
end
