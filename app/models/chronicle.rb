# type: Post
#
class Chronicle < ApplicationRecordForContentAndPosts
  YID_CODE = "cron".freeze

  belongs_to :team, inverse_of: :chronicles, foreign_key: "team_yid"

  # NOTE: insights can be pictures, locations, weblinks
  has_many :insights, inverse_of: :chronicles, foreign_key: "insight_yid", dependent: :delete_all

  multisearchable(
    against: %i[note], # TODO: too much content for full-text-search?!
    additional_attributes: ->(chronicle) { { team_yid: chronicle.team_yid } }
  )

  attr_readonly :team_yid

  normalizes :note, with: ->(note) { note.strip }

  validates :name, presence: true
  validates :notes, presence: true, length: { minimum: 20, maximum: 5000 } # TODO: more for paying users?
  validates :visibility, presence: true, inclusion: { in: VISIBILITY_STATES }
end
