# frozen_string_literal: true

# type: PostEntry
#
class ChronicleEntry < ApplicationRecordYidEnabled
  YID_CODE = "crent"

  VALID_ENTRY_TYPES = %w[Memory Picture Location Thought Weblink].freeze

  default_scope { order(position: :asc) }

  belongs_to :team, inverse_of: false
  belongs_to :chronicle, inverse_of: :entries
  belongs_to :entry, polymorphic: true

  positioned on: :chronicle

  before_validation :assign_team_from_chronicle, if: -> { team_id.blank? && chronicle.present? }

  attr_readonly :team_id

  after_create :align_entry_visibility

  validates :entry_type, presence: true, inclusion: { in: VALID_ENTRY_TYPES }
  validates :position, presence: true, on: :update
  validate :team_matches_chronicle
  validate :entry_belongs_to_same_team

  private

  def align_entry_visibility
    return if entry.blank? || chronicle.blank?
    return if entry.visibility == chronicle.visibility
    return if entry.highest_parent_visibility_level(except_parent: chronicle) > chronicle.visibility_level

    entry.update(visibility: chronicle.visibility)
  end

  def assign_team_from_chronicle
    self.team_id = chronicle.team_id
  end

  def team_matches_chronicle
    return if team_id.blank? || chronicle.blank?
    return if team_id == chronicle.team_id

    errors.add(:team_id, "must match the chronicle team")
  end

  def entry_belongs_to_same_team
    return if entry.blank? || chronicle.blank?
    return unless entry.respond_to?(:team_id)
    return if entry.team_id == chronicle.team_id

    errors.add(:entry, "must belong to the same team as the chronicle")
  end
end
