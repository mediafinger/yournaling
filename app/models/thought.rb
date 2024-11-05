# type: Content
#
class Thought < ApplicationRecordForContentAndPosts
  YID_CODE = "thot".freeze

  belongs_to :team, inverse_of: :thoughts

  has_many :memories, class_name: "Memory", inverse_of: :thought,
    dependent: :nullify

  multisearchable(
    against: %i[text date],
    additional_attributes: ->(thought) { { team_id: thought.team_id } }
  )

  attr_readonly :team_id

  normalizes :text, with: ->(text) { text.strip }

  validates :text, presence: true, length: { in: 1..512 }
  validates :visibility, presence: true, inclusion: { in: VISIBILITY_STATES }
end
