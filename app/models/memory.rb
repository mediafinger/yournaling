# frozen_string_literal: true

# type: Post
#
# Memory.memo and an optional Thought feel like basically the same thing.
# We keep it this way for now to optimize fast text-only memory creation and querying.
#
class Memory < ApplicationRecordForContentAndPosts
  include VisibilityConstrainedByParents
  include Publishable

  YID_CODE = "memo"

  INSIGHT_PARAM_KEYS = %i[
    picture_id picture_file picture_name
    location_id location_name location_address location_country_code location_url location_description
    thought_id thought_text
    weblink_id weblink_name weblink_url weblink_description
  ].freeze
  INLINE_INSIGHT_ATTRIBUTES = (INSIGHT_PARAM_KEYS - %i[picture_id location_id thought_id weblink_id]).freeze
  attr_accessor(*INLINE_INSIGHT_ATTRIBUTES)

  normalizes :location_id, :picture_id, :thought_id, :weblink_id, with: ->(id) { id.presence }

  belongs_to :team, inverse_of: :memories
  belongs_to :location, inverse_of: :memories, optional: true
  belongs_to :picture, inverse_of: :memories, optional: true
  belongs_to :thought, inverse_of: :memories, optional: true
  belongs_to :weblink, inverse_of: :memories, optional: true

  has_many :chronicle_entries, as: :entry, dependent: :destroy
  has_many :chronicles, -> { distinct.reorder("chronicles.created_at DESC") }, through: :chronicle_entries

  multisearchable(
    against: %i[memo],
    additional_attributes: ->(memory) { { team_id: memory.team_id } }
  )

  attr_readonly :team_id

  scope :with_includes, -> { includes(:team, :location, :picture, :thought, :weblink) }

  after_save :cascade_visibility_to_insights, if: :saved_change_to_visibility?
  after_save :align_insights_visibility

  normalizes :memo, with: ->(memo) { memo.strip }

  validates :memo, presence: true, length: { minimum: 4, maximum: 512 }
  validates :location, presence: true, if: -> { location_id.present? }
  validates :picture, presence: true, if: -> { picture_id.present? }
  validates :thought, presence: true, if: -> { thought_id.present? }
  validates :weblink, presence: true, if: -> { weblink_id.present? }
  validates :visibility, presence: true, inclusion: { in: VISIBILITY_STATES }

  private

  def cascade_visibility_to_insights
    %i[location picture thought weblink].each do |type|
      insight = send(type)
      next if insight.blank?
      next if insight.visibility == visibility
      next if insight.highest_parent_visibility_level(except_parent: self) > visibility_level

      insight.update(visibility:)
    end
  end

  def align_insights_visibility
    %i[location picture thought weblink].each do |type|
      update_visibility_of_removed_insight(type)

      insight = send(type)
      next if insight.blank?
      next if insight.visibility == visibility
      next if insight.highest_parent_visibility_level(except_parent: self) > visibility_level

      insight.update(visibility:)
    end
  end

  def update_visibility_of_removed_insight(type)
    return unless saved_changes.key?(:"#{type}_id")

    removed_id = saved_changes[:"#{type}_id"].first
    return if removed_id.blank?

    removed_insight = ApplicationRecordYidEnabled.fynd(removed_id)
    return if removed_insight.blank?
    return if removed_insight.memories.where.not(id:).exists?
    return if removed_insight.chronicles.exists?

    removed_insight.update(visibility: :internal)
  end
end
