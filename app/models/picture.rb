# file uploads are limited to images: content_type: %w[image/gif image/jpg image/jpeg image/png]
# in the size of 50.kilobytes to 10.megabytes
# two variants are created: thumbnail (max: 400x300) and megasize (max: 4000x3000)
# ideally we would delete the original file after the variants are created, but I didn't find a working solution yet
# if deleting the original should not be possible, we should prevent uploading 10 MB files
# and introduce a smaller limit - at least for non-paying users

class Picture < ApplicationRecord
  has_one_attached :file

  validates :name, allow_blank: true, length: { maximum: 255 }
  validates :file, presence: true, image: {
    content_type: %w[image/gif image/jpg image/jpeg image/png], size_range: (50.kilobytes..10.megabytes)
  } # this uses the custom ImageValidator

  # limit additionally to less than 100 KByte ?
  def thumbnail
    file.variant(resize_to_limit: [400, 300], format: :jpeg, saver: { quality: 90 }).processed
  end

  # around 12 MP, limit additionally to less than X MByte ?
  def megasize
    file.variant(resize_to_limit: [4000, 3000], format: :jpeg, saver: { quality: 80 }).processed
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
  #   file.variant(resize_to_fill: [400, 400], format: :jpeg, saver: { quality: 80 }).processed
  # end

  # # use for profile pictures
  # TODO: crop to square
  # def square_bw
  #   file.variant(resize_to_fill: [400, 400], format: :jpeg, saver: { quality: 80 }, colourspace: "b-w").processed
  # end

  # private

  def path
    ActiveStorage::Blob.service.path_for(file.key)
  end

  # date_time is completely off, gps is nil :-/
  def exif
    EXIFR::JPEG.new(Picture.last.path) # if JPEG
  end

  def vips
    image = Vips::Image.new_from_file(path)

    {
      width: image.width,
      height: image.height,
    }
  end
end
