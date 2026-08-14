# frozen_string_literal: true

# type: Post
#
class Chronicle < ApplicationRecordForContentAndPosts
  YID_CODE = "cron"

  belongs_to :team, inverse_of: :chronicles

  has_many :chronicle_entries, -> { order(position: :asc) }, inverse_of: :chronicle, dependent: :destroy

  has_many :memories, through: :chronicle_entries, source: :entry, source_type: "Memory"
  has_many :pictures, through: :chronicle_entries, source: :entry, source_type: "Picture"
  has_many :locations, through: :chronicle_entries, source: :entry, source_type: "Location"
  has_many :thoughts, through: :chronicle_entries, source: :entry, source_type: "Thought"
  has_many :weblinks, through: :chronicle_entries, source: :entry, source_type: "Weblink"

  accepts_nested_attributes_for :chronicle_entries, allow_destroy: true

  multisearchable(
    against: %i[name notice],
    additional_attributes: ->(chronicle) { { team_id: chronicle.team_id } }
  )

  attr_readonly :team_id

  normalizes :name, with: ->(name) { name.strip }
  normalizes :notice, with: ->(notice) { notice.strip }

  validates :name, presence: true, uniqueness: { scope: :team_id }
  validates :notice, presence: true, length: { minimum: 20, maximum: 4096 }
  validates :start_date, presence: true
  validates :visibility, presence: true, inclusion: { in: VISIBILITY_STATES }
  validate :validate_date_range

  private

  def validate_date_range
    return if end_date.blank? || start_date.blank?

    errors.add(:end_date, "must be on or after start date") if end_date < start_date
  end
end
