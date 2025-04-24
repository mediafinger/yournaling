# type: Content
#
# file uploads are limited to images: content_type: %w[image/gif image/jpeg image/webp image/png]
# after conversion to webp the file has to be in the size of 150.kilobytes to 6.megabytes
# two variants are created: thumbnail (max: 400x300) and megasize (max: 4000x3000)
# ideally we would delete the original file after the variants are created, but I didn't find a working solution yet
# if deleting the original should not be possible, we should prevent uploading files larger than 10 MB
# and introduce a smaller limit - at least for non-paying users
#
class Picture < ApplicationRecordForContentAndPosts
  extend ActionView::Helpers::NumberHelper

  has_one_attached :file

  ALLOWED_IMAGE_TYPES = %w[gif jpeg png tiff webp].freeze
  ALLOWED_CONTENT_TYPES = ALLOWED_IMAGE_TYPES.map { |type| "image/#{type}" }.freeze
  MAX_BYTE_SIZE = 6.megabytes.freeze
  MIN_BYTE_SIZE = 150.kilobytes.freeze
  MAX_PIXEL_HEIGHT = 4000
  MIN_PIXEL_HEIGHT = 400
  MAX_PIXEL_WIDTH = 4000
  MIN_PIXEL_WIDTH = 400
  YID_CODE = "pic".freeze

  belongs_to :team, inverse_of: :pictures

  has_many :memories, class_name: "Memory", inverse_of: :picture,
    dependent: :nullify

  multisearchable(
    against: %i[name],
    additional_attributes: ->(picture) { { team_id: picture.team_id } }
  )

  attr_readonly :team_id

  normalizes :name, with: ->(name) { name.strip }

  # NOTE
  # In PicturesController#create the uploaded files are resized (downsized) to max of MAX_PIXEL_WIDTH x MAX_PIXEL_HEIGHT
  # and converted to .webp with a quality of 90% with the ImageUploadConversionService
  # *before* being saved to disk.
  #
  # validation after the original image has been resized and converted to webp
  # uses the active_storage_validations gem
  # currently allowing all content_types, not only webp which it should be after conversion
  #
  # see: https://github.com/igorkasyanchuk/active_storage_validations
  #
  validates :file, attached: true,
    size: {
      between: (MIN_BYTE_SIZE..MAX_BYTE_SIZE),
      message: I18n.t(
        "errors.messages.file_size_not_between",
        max_size: number_to_human_size(MAX_BYTE_SIZE),
        min_size: number_to_human_size(MIN_BYTE_SIZE),
        file_size: number_to_human_size(0) # file&.blob&.size) # TODO
      ),
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
  # TODO: add validation to allow range of aspect ratios (e.g. width / height between 2/3 and 3/2)
  # TODO: or crop original image to fit landscape / square / portrait variants

  validates :name, allow_blank: true, length: { maximum: 255 }
  validates :visibility, presence: true, inclusion: { in: VISIBILITY_STATES }

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

  def content_type
    file.blob.content_type
  end

  def filename
    file.blob.filename.to_s # TODO: should the service store with or without suffix?!
  end

  def height
    file.blob.metadata[:height] # TODO: nil (or only before saving?)
  end

  def width
    raise "picture.id: #{id}, file: #{file}" if file.blob.nil?

    file.blob.metadata[:width] # TODO: nil (or only before saving?)
  end

  def uploaded_at
    file.blob.created_at
  end

  # # use for profile pictures
  # TODO: crop to square
  # def square
  #   file.variant(resize_to_fill: [400, 400], format: :webp, saver: { quality: 80 }).processed
  # end

  # # use for profile pictures
  # TODO: crop to square
  # def square_bw
  #   file.variant(resize_to_fill: [400, 400], format: :webp, saver: { quality: 80 }, colourspace: "b-w").processed
  # end

  # private

  def path
    ActiveStorage::Blob.service.path_for(file.key)
  end

  def vips
    require "ruby-vips" # TODO: nicefy

    image = ::Vips::Image.new_from_file(path)

    {
      width: image.width,
      height: image.height,
    }
  end
end
