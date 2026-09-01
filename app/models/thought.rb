# frozen_string_literal: true

# type: Content
#
# TODO
# in the schema we create a virtual column "name":
# t.virtual "name", type: :string, as: "(\"substring\"(text, 0, 60) || '...'::text)", stored: true
# in case we only added this for the search, is this then still necessary after we improved the search?
# If not, we should remove this (and similar now redundant patterns on other tables).
#
class Thought < ApplicationRecordForContentAndPosts
  include VisibilityConstrainedByParents

  YID_CODE = "thot"

  belongs_to :team, inverse_of: :thoughts
  has_many :chronicle_entries, as: :entry, dependent: :destroy
  has_many :chronicles, -> { distinct.reorder("chronicles.created_at DESC") }, through: :chronicle_entries
  has_many :memories, class_name: "Memory", inverse_of: :thought,
    dependent: :nullify

  multisearchable(
    against: %i[text date],
    additional_attributes: ->(thought) { { team_id: thought.team_id } }
  )

  attr_readonly :team_id

  normalizes :text, with: ->(text) { text.strip }

  validates :text, presence: true, length: { in: 1..1024 }
  validates :visibility, presence: true, inclusion: { in: VISIBILITY_STATES }
end
