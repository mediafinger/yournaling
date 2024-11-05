# type: Post
#
class Memory < ApplicationRecordForContentAndPosts
  YID_CODE = "memo".freeze

  belongs_to :team, inverse_of: :memories
  belongs_to :location, inverse_of: :memories, optional: true
  belongs_to :picture, inverse_of: :memories, optional: true
  belongs_to :thought, inverse_of: :memories, optional: true
  belongs_to :weblink, inverse_of: :memories, optional: true

  multisearchable(
    against: %i[memo], # TODO: thought.name, picture.name, weblink.name, location.name
    additional_attributes: ->(memory) { { team_id: memory.team_id } }
  )

  attr_readonly :team_id

  scope :with_includes, -> { includes(:team, :location, :picture, :thought, :weblink) }

  before_save :update_visibilty_of_insights

  normalizes :memo, with: ->(memo) { memo.strip }

  validates :memo, presence: true, length: { minimum: 4, maximum: 500 }
  validates :location, presence: true, if: -> { location_id.present? }
  validates :picture, presence: true, if: -> { picture_id.present? }
  validates :thought, presence: true, if: -> { thought_id.present? }
  validates :weblink, presence: true, if: -> { weblink_id.present? }
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
      %i[location picture thought weblink].each do |type|
        update_visibility_of_removed_insight(type)

        # update visibility of associated insight to the visibility of this memory
        send(type).update(visibility:) if send(type).present?
      end
    end
  end

  def update_visibility_of_removed_insight(type)
    removed_id = send(:"#{type}_id_was")
    return if removed_id.blank? # no previous Insight present, nothing to do
    return if removed_id == send(:"#{type}_id") # Insight did not change, nothing to do

    removed_insight = ApplicationRecordYidEnabled.fynd(removed_id)
    return if removed_insight.blank? # Insight does not exist anymore, nothing to do
    return if removed_insight.memories.where.not(id:).exists? # Insight still used by other objects, nothing to do

    removed_insight.update(visibility: :internal) # reduce visibility of Insight to owning team
  end
end
