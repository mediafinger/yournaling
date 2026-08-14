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

  attr_readonly :team_id

  validates :entry_type, presence: true, inclusion: { in: VALID_ENTRY_TYPES }
  validates :position, presence: true # TODO: validate it's a positive integer
end
