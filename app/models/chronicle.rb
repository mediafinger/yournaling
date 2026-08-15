# frozen_string_literal: true

# type: Post
#
class Chronicle < ApplicationRecordForContentAndPosts
  YID_CODE = "cron"

  belongs_to :team, inverse_of: :chronicles

  has_many :chronicle_entries, -> { reorder(position: :asc) }, inverse_of: :chronicle, dependent: :destroy

  has_many :memories, -> {
    reorder("chronicle_entries.position ASC")
  }, through: :chronicle_entries, source: :entry, source_type: "Memory"
  has_many :pictures, -> {
    reorder("chronicle_entries.position ASC")
  }, through: :chronicle_entries, source: :entry, source_type: "Picture"
  has_many :locations, -> {
    reorder("chronicle_entries.position ASC")
  }, through: :chronicle_entries, source: :entry, source_type: "Location"
  has_many :thoughts, -> {
    reorder("chronicle_entries.position ASC")
  }, through: :chronicle_entries, source: :entry, source_type: "Thought"
  has_many :weblinks, -> {
    reorder("chronicle_entries.position ASC")
  }, through: :chronicle_entries, source: :entry, source_type: "Weblink"

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

  attr_accessor :picture_id, :picture_file, :picture_name

  def attach_picture(picture_id: nil, picture_file: nil, picture_name: nil, user: nil)
    target_picture = if picture_file.respond_to?(:tempfile)
                       p_name = picture_name.presence || File.basename(picture_file.original_filename, ".*").titleize
                       pic = Picture.new(
                         file: ImageUploadConversionService.call(file: picture_file, name: p_name),
                         name: p_name,
                         date: start_date,
                         team: team,
                         visibility: visibility
                       )
                       Picture.create_with_event(record: pic, event_params: { team: team, user: user })
                       pic if pic.persisted?
                     elsif picture_id.present?
                       team.pictures.find_by(id: picture_id)
                     end

    return unless target_picture

    chronicle_entries.create!(
      entry: target_picture,
      team: team
    )
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
    chronicle_entries.each do |chronicle_entry|
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
