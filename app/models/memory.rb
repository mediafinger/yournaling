# type: Post
#
class Memory < ApplicationRecordForContentAndPosts
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
  # REFACT: ensure the transaction is rolled back, when the memory can not be saved
  #
  # TODO: ensure updated associations are always saved!
  #
  # TODO: OR keep insights always internal and never set them to :published,
  # so they can only be seen in the context of the Memory... (??)
  #
  def update_visibilty_of_insights
    transaction do
      %i[location picture weblink].each do |type|
        update_visibility_of_removed_insight(type)

        # update visibility of associated insight to the visibility of this memory
        send(type).update(visibility:) if send(type).present?
      end
    end
  end

  def update_visibility_of_removed_insight(type)
    removed_yid = send(:"#{type}_yid_was")
    return if removed_yid.blank? # no previous Insight present, nothing to do
    return if removed_yid == send(:"#{type}_yid") # Insight did not change, nothing to do

    removed_insight = ApplicationRecordYidEnabled.fynd(removed_yid)
    return if removed_insight.blank? # Insight does not exist anymore, nothing to do
    return if removed_insight.memories.where.not(yid:).exists? # Insight still used by other objects, nothing to do

    removed_insight.update(visibility: :internal) # reduce visibility of Insight to owning team
  end
end
