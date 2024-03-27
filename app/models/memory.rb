class Memory < ApplicationRecordForContent
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

  normalizes :memo, with: ->(memo) { memo.strip }

  validates :memo, presence: true, length: { minimum: 4, maximum: 500 }
  validates :location, presence: true, if: -> { location_yid.present? }
  validates :picture, presence: true, if: -> { picture_yid.present? }
  validates :weblink, presence: true, if: -> { weblink_yid.present? }
  validates :visibility, presence: true, inclusion: { in: VISIBILITY_STATES }
end
