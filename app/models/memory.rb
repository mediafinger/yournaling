class Memory < ApplicationRecordForContent
  YID_CODE = "memo".freeze

  belongs_to :team, inverse_of: :memories, foreign_key: "team_yid"
  belongs_to :location, inverse_of: :memories, foreign_key: "location_yid", optional: true
  belongs_to :picture, inverse_of: :memories, foreign_key: "picture_yid", optional: true
  belongs_to :weblink, inverse_of: :memories, foreign_key: "weblink_yid", optional: true

  multisearchable(
    against: %i[memo],
    additional_attributes: ->(memory) { { team_yid: memory.team_yid } }
  )

  attr_readonly :team_yid

  scope :with_includes, -> { includes(:team, :location, :picture, :weblink) }

  before_save :update_visibilty_of_insights

  normalizes :memo, with: ->(memo) { memo.strip }

  validates :memo, presence: true, length: { minimum: 4, maximum: 500 }
  validates :location, presence: true, if: -> { location_yid.present? }
  validates :picture, presence: true, if: -> { picture_yid.present? }
  validates :weblink, presence: true, if: -> { weblink_yid.present? }
  validates :visibility, presence: true, inclusion: { in: VISIBILITY_STATES }

  private

  # REFACT: extract this to a service or similar
  #
  def update_visibilty_of_insights
    update_visibility_of_removed_locations
    update_visibility_of_removed_pictures
    update_visibility_of_removed_weblinks

    location.visibility = visibility if location.present?
    picture.visibility = visibility if picture.present?
    weblink.visibility = visibility if weblink.present?
  end

  def update_visibility_of_removed_locations
    return unless location_yid_was != location_yid # Location did not change, nothing to do

    removed_loc = Location.find_by(yid: location_yid_was)
    return if removed_loc.blank? # Location does not exist anymore, nothing to do
    return if removed_loc.memories.any? # Location is still used by other objects, nothing to do

    removed_loc.visibility = :internal # reduce visibility of Location to owning team
  end

  def update_visibility_of_removed_pictures
    return unless picture_yid_was != picture_yid # Picture did not change, nothing to do

    removed_pic = Picture.find_by(yid: picture_yid_was)
    return if removed_pic.blank? # Picture does not exist anymore, nothing to do
    return if removed_pic.memories.any? # Picture is still used by other objects, nothing to do

    removed_pic.visibility = :internal # reduce visibility of Picture to owning team
  end

  def update_visibility_of_removed_weblinks
    return unless weblink_yid_was != weblink_yid # Weblink did not change, nothing to do

    removed_link = Weblink.find_by(yid: weblink_yid_was)
    return if removed_link.blank? # Weblink does not exist anymore, nothing to do
    return if removed_link.memories.any? # Weblink is still used by other objects, nothing to do

    removed_link.visibility = :internal # reduce visibility of Weblink to owning team
  end
end
