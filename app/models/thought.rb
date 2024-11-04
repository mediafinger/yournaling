# type: Content
#
class Thought < ApplicationRecordForContentAndPosts
  YID_CODE = "thot".freeze

  belongs_to :team, inverse_of: :thoughts, foreign_key: "team_yid"

  has_many :memories, class_name: "Memory", foreign_key: "thought_yid", primary_key: "yid", inverse_of: :thought,
    dependent: :nullify

  multisearchable(
    against: %i[text date],
    additional_attributes: ->(thought) { { team_yid: thought.team_yid } }
  )

  attr_readonly :team_yid

  normalizes :text, with: ->(text) { text.strip }

  validates :text, presence: true, length: { in: 1..512 }
  validates :team_yid, presence: true
  validates :visibility, presence: true, inclusion: { in: VISIBILITY_STATES }
end
