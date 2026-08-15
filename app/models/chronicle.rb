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

  class << self
    # Preloads ActiveStorage file attachments and blobs for all pictures associated
    # with the given chronicles to prevent N+1 queries when rendering images/variants.
    # Uses in-memory chronicle_entries when already loaded to avoid extra queries.
    #
    # Example:
    #   chronicles = Chronicle.includes(chronicle_entries: :entry)
    #   Chronicle.preload_attachments(chronicles)
    #
    def preload_attachments(chronicles)
      records = Array(chronicles)
      pictures = records.flat_map do |c|
        if c.chronicle_entries.loaded?
          c.chronicle_entries.filter_map { |ce| ce.entry if ce.entry_type == "Picture" }
        else
          c.pictures
        end
      end
      ActiveRecord::Associations::Preloader.new(records: pictures, associations: { file_attachment: :blob }).call
      chronicles
    end
  end

  def first_picture
    if chronicle_entries.loaded?
      chronicle_entries.find { |ce| ce.entry_type == "Picture" }&.entry
    else
      chronicle_entries.where(entry_type: "Picture").reorder(position: :asc).first&.entry
    end
  end

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
