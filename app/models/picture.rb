# frozen_string_literal: true

# type: Content
#
# Upload pipeline (see README_PICTURES.md):
#   1. Picture#assign_uploaded_file reads EXIF + geometry from the ORIGINAL
#      upload via Images::MetadataExtractor and stores it in dedicated columns
#      (taken_at, latitude, longitude, altitude, camera_*, image_*).
#   2. ImageUploadConversionService downsizes, auto-rotates, re-encodes to WebP
#      and strips EXIF/GPS — that stripped WebP is what gets attached as `file`.
#
# So the stored file is "anonymous"; the coordinates/timestamp survive only in
# the database, where the app can use them (map placement, chronology) without
# leaking them to anyone who downloads the image.
#
class Picture < ApplicationRecordForContentAndPosts
  extend ActionView::Helpers::NumberHelper
  include VisibilityConstrainedByParents

  has_one_attached :file

  ALLOWED_IMAGE_TYPES = %w[gif jpeg png tiff webp].freeze
  ALLOWED_CONTENT_TYPES = ALLOWED_IMAGE_TYPES.map { |type| "image/#{type}" }.freeze
  MAX_BYTE_SIZE = AppConf.picture_max_byte_size.to_i
  MIN_BYTE_SIZE = AppConf.picture_min_byte_size.to_i
  MAX_PIXEL_HEIGHT = AppConf.picture_max_pixels.to_i
  MIN_PIXEL_HEIGHT = AppConf.picture_min_pixels.to_i
  MAX_PIXEL_WIDTH = AppConf.picture_max_pixels.to_i
  MIN_PIXEL_WIDTH = AppConf.picture_min_pixels.to_i
  YID_CODE = "pic"

  # WebP encode quality (0..100) used by ImageUploadConversionService.
  def self.webp_quality = AppConf.picture_webp_quality.to_i

  # Whether the stored file has its EXIF/GPS/ICC metadata removed.
  def self.strip_metadata? = ActiveModel::Type::Boolean.new.cast(AppConf.picture_strip_metadata)

  belongs_to :team, inverse_of: :pictures
  has_many :chronicle_entries, as: :entry, dependent: :destroy
  has_many :chronicles, -> { distinct.reorder("chronicles.created_at DESC") }, through: :chronicle_entries
  has_many :memories, class_name: "Memory", inverse_of: :picture,
    dependent: :nullify

  multisearchable(
    against: %i[name],
    additional_attributes: ->(picture) { { team_id: picture.team_id } }
  )

  attr_readonly :team_id

  normalizes :name, with: ->(name) { name.strip }

  # NOTE
  # In the PicturesControllers the uploaded file is resized to max of
  # MAX_PIXEL_WIDTH x MAX_PIXEL_HEIGHT and converted to .webp *before* being
  # saved, by Picture#assign_uploaded_file -> ImageUploadConversionService.
  #
  # The validations below therefore run against the already-converted WebP,
  # using the active_storage_validations gem. Messages come from
  # config/locales/active_storage_validations.en.yml (which interpolates the
  # real file size / dimensions).
  #
  # see: https://github.com/igorkasyanchuk/active_storage_validations
  #
  validates :file, attached: true,
    size: {
      between: (MIN_BYTE_SIZE..MAX_BYTE_SIZE),
    },
    content_type: {
      in: ALLOWED_CONTENT_TYPES,
      message: I18n.t(
        "errors.messages.content_type_invalid",
        allowed_types: ALLOWED_IMAGE_TYPES.join(", ")
      ),
    },
    dimension: {
      width: {
        min: MIN_PIXEL_WIDTH, max: MAX_PIXEL_WIDTH,
        message: I18n.t("errors.messages.dimension_width_inclusion", min: MIN_PIXEL_WIDTH, max: MAX_PIXEL_WIDTH)
      },
      height: {
        min: MIN_PIXEL_HEIGHT, max: MAX_PIXEL_HEIGHT,
        message: I18n.t("errors.messages.dimension_height_inclusion", min: MIN_PIXEL_HEIGHT, max: MAX_PIXEL_HEIGHT)
      },
    }

  validates :name, allow_blank: true, length: { maximum: 255 }
  validates :visibility, presence: true, inclusion: { in: VISIBILITY_STATES }
  validates :exif_stripped, inclusion: { in: [true, false] }
  validates :latitude, allow_nil: true,
    numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, allow_nil: true,
    numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }

  # Reads EXIF + geometry from the original upload, records it, then attaches
  # the converted (downsized, WebP, EXIF-stripped) file. Returns the
  # Images::Metadata so the caller can surface suggestions to the user.
  #
  #   picture.assign_uploaded_file(params[:file], name: params[:name], date: params[:date])
  #
  def assign_uploaded_file(uploaded_file, name:, date: nil)
    metadata = Images::MetadataExtractor.call(uploaded_file)

    assign_attributes(metadata.to_picture_attributes)
    self.exif_stripped = self.class.strip_metadata?
    self.name = name
    self.date = date.presence || metadata.taken_at&.to_date
    self.file = ImageUploadConversionService.call(file: uploaded_file, name: name)

    metadata
  end

  def thumbnail
    create_variant(max_width: 160, max_height: 120)
  end

  def preview
    create_variant(max_width: 400, max_height: 300, quality: 85)
  end

  def large
    create_variant(max_width: 1200, max_height: 900, quality: 90)
  end

  # NOTE: on demand variants, maybe persist a few sizes
  def create_variant(max_width:, max_height:, quality: 80, format: :webp)
    return unless persisted? && file.attached?

    file.variant(resize_to_limit: [max_width, max_height], format:, saver: { quality: }).processed
  end

  def bytes
    file.blob.byte_size
  end

  def kilobytes
    bytes / 1024
  end

  def megabytes
    (bytes / 1024.0 / 1024).round(2)
  end

  # Size of the file the user actually selected, before server-side conversion.
  def original_size
    self.class.number_to_human_size(original_byte_size) if original_byte_size
  end

  def content_type
    file.blob.content_type
  end

  def filename
    file.blob.filename.to_s
  end

  # Display dimensions. Prefer the columns captured at upload; fall back to the
  # attached blob's analyzed metadata for pre-existing records.
  def dimensions
    width = image_width || file.blob&.metadata&.dig(:width)
    height = image_height || file.blob&.metadata&.dig(:height)

    [width, height] if width && height
  end

  def width
    dimensions&.first
  end

  def height
    dimensions&.last
  end

  # :landscape | :portrait | :square | nil
  def orientation
    width, height = dimensions
    return if width.nil? || height.nil?
    return :square if width == height

    width > height ? :landscape : :portrait
  end

  def landscape? = orientation == :landscape
  def portrait? = orientation == :portrait
  def square? = orientation == :square

  # width : height, e.g. 1.7778 for 16:9. nil when dimensions are unknown.
  def aspect_ratio
    width, height = dimensions
    return if width.nil? || height.nil? || height.zero?

    (width.to_f / height).round(4)
  end

  def geotagged?
    latitude.present? && longitude.present?
  end

  def coordinates
    [latitude, longitude] if geotagged?
  end

  def camera
    [camera_make, camera_model].compact_blank.join(" ").presence
  end

  # The date to suggest for this picture (and any chronicle it joins).
  def suggested_date
    taken_at&.to_date
  end

  # Attributes to pre-fill a Location form from this photo's GPS fix.
  # (A Location still needs a name + country; the app reverse-geocodes the rest.)
  def location_attributes_from_exif
    return {} unless geotagged?

    { lat: latitude, long: longitude }
  end

  def uploaded_at
    file.blob.created_at
  end

  def path
    ActiveStorage::Blob.service.path_for(file.key)
  end
end
