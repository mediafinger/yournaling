# frozen_string_literal: true

# type: PostEntry
#
class ChronicleEntry < ApplicationRecordYidEnabled
  YID_CODE = "crent"

  VALID_ENTRY_TYPES = %w[Memory Picture Location Thought Weblink].freeze

  belongs_to :team, inverse_of: false
  belongs_to :chronicle, inverse_of: :chronicle_entries
  belongs_to :entry, polymorphic: true

  positioned on: :chronicle

  before_validation :assign_team_from_chronicle, if: -> { team_id.blank? && chronicle.present? }

  # TODO: add validation that team_id and chronicle_team_id are always the same

  attr_readonly :team_id

  validates :entry_type, presence: true, inclusion: { in: VALID_ENTRY_TYPES }
  validates :position, presence: true # TODO: validate it's a positive integer

  private

  def assign_team_from_chronicle
    self.team_id = chronicle.team_id
  end
end
