# file uploads are limited to images: content_type: %w[image/gif image/jpg image/webp image/png]
# in the size of 50.kilobytes to 10.megabytes
# two variants are created: thumbnail (max: 400x300) and megasize (max: 4000x3000)
# ideally we would delete the original file after the variants are created, but I didn't find a working solution yet
# if deleting the original should not be possible, we should prevent uploading 10 MB files
# and introduce a smaller limit - at least for non-paying users

class Picture < ApplicationRecordYidEnabled
  has_one_attached :file

  ALLOWED_IMAGE_TYPES = %w[gif jpg jpeg png tiff webp].freeze
  ALLOWED_CONTENT_TYPES = ALLOWED_IMAGE_TYPES.map { |type| "image/#{type}" }.freeze
  YID_MODEL = "pic".freeze

  # NOTE
  # In PicturesController#create the uploaded files are resized (downsized) to to max of 4000x3000
  # and converted to .webp with a quality of 90% *before* being saved to disk.
  #
  validates :file, presence: true, image: { # this is after the original image has been resized and converted to webp
    content_type: %w[image/webp], size_range: (150.kilobytes..6.megabytes)
  } # this uses the custom ImageValidator
  validates :name, allow_blank: true, length: { maximum: 255 }

  def thumbnail
    create_variant(max_width: 160, max_height: 120)
  end

  def preview
    create_variant(max_width: 400, max_height: 300, quality: 85)
  end

  def large
    create_variant(max_width: 1200, max_height: 900, quality: 90)
  end

  def create_variant(max_width:, max_height:, quality: 80, format: :webp)
    file.variant(resize_to_limit: [max_width, max_height], format: format, saver: { quality: quality }).processed
  end

  def kilobytes
    file.blob.byte_size / 1024
  end

  def megabytes
    (file.blob.byte_size / 1024.0 / 1024).round(2)
  end

  def content_type
    file.blob.content_type
  end

  def filename
    file.blob.filename.to_s
  end

  def height
    file.blob.metadata[:height]
  end

  def width
    raise "picture.id: #{id}, file: #{file}" if file.blob.nil?

    file.blob.metadata[:width]
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
    image = Vips::Image.new_from_file(path)

    {
      width: image.width,
      height: image.height,
    }
  end
end
