# frozen_string_literal: true

# type: Post
#
class Chronicle < ApplicationRecordForContentAndPosts
  include ChronicleAttachableInsights

  YID_CODE = "cron"

  belongs_to :team, inverse_of: :chronicles

  has_many :entries, -> {
    reorder(position: :asc)
  }, class_name: "ChronicleEntry", inverse_of: :chronicle, dependent: :destroy

  has_many :memories, -> {
    reorder("chronicle_entries.position ASC")
  }, through: :entries, source: :entry, source_type: "Memory"
  has_many :pictures, -> {
    reorder("chronicle_entries.position ASC")
  }, through: :entries, source: :entry, source_type: "Picture"
  has_many :locations, -> {
    reorder("chronicle_entries.position ASC")
  }, through: :entries, source: :entry, source_type: "Location"
  has_many :thoughts, -> {
    reorder("chronicle_entries.position ASC")
  }, through: :entries, source: :entry, source_type: "Thought"
  has_many :weblinks, -> {
    reorder("chronicle_entries.position ASC")
  }, through: :entries, source: :entry, source_type: "Weblink"

  accepts_nested_attributes_for :entries, allow_destroy: true

  class << self
    # Preloads ActiveStorage file attachments and blobs for all pictures associated
    # with the given chronicles to prevent N+1 queries when rendering images/variants.
    # Uses in-memory entries when already loaded to avoid extra queries.
    #
    # Example:
    #   chronicles = Chronicle.includes(entries: :entry)
    #   Chronicle.preload_attachments(chronicles)
    #
    def preload_attachments(chronicles)
      records = Array(chronicles)
      pictures = records.flat_map do |c|
        if c.entries.loaded?
          c.entries.filter_map { |ce| ce.entry if ce.entry_type == "Picture" }
        else
          c.pictures
        end
      end
      ActiveRecord::Associations::Preloader.new(records: pictures, associations: { file_attachment: :blob }).call
      chronicles
    end
  end

  def first_picture
    if entries.loaded?
      entries.find { |ce| ce.entry_type == "Picture" }&.entry
    else
      entries.where(entry_type: "Picture").reorder(position: :asc).first&.entry
    end
  end

  multisearchable(
    against: %i[name notice],
    additional_attributes: ->(chronicle) { { team_id: chronicle.team_id } }
  )

  attr_readonly :team_id

  normalizes :name, with: ->(name) { name.strip }
  normalizes :notice, with: ->(notice) { notice.strip }

  after_save :cascade_visibility_to_entries, if: :saved_change_to_visibility?

  validates :name, presence: true, uniqueness: { scope: :team_id }
  validates :notice, presence: true, length: { minimum: 20, maximum: 4096 }
  validates :start_date, presence: true
  validates :visibility, presence: true, inclusion: { in: VISIBILITY_STATES }
  validate :validate_date_range

  private

  # TODO: improve performance when we see Chronicles with dozens of entries
  def cascade_visibility_to_entries
    entries.each do |chronicle_entry|
      entry = chronicle_entry.entry
      next if entry.blank?
      next if entry.visibility == visibility
      next if entry.highest_parent_visibility_level(except_parent: self) > visibility_level

      entry.update(visibility:)
    end
  end

  def validate_date_range
    return if end_date.blank? || start_date.blank?

    errors.add(:end_date, "must be on or after start date") if end_date < start_date
  end
end
