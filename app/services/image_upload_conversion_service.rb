# frozen_string_literal: true

# Converts an uploaded image into the canonical stored form:
#   * auto-rotated so the pixels are upright (EXIF Orientation is honoured by
#     libvips' thumbnail step, then dropped)
#   * downsized so neither edge exceeds Picture::MAX_PIXEL_* (aspect kept)
#   * re-encoded as WebP at AppConf.picture_webp_quality
#   * stripped of EXIF / GPS / ICC metadata (AppConf.picture_strip_metadata)
#
# EXIF is read *before* this runs (see Images::MetadataExtractor /
# Picture#assign_uploaded_file) because this step destroys it.
#
# NOTE: needs the libvips system library. Raises ImageTooSmall for images below
# the minimum pixel size, and Vips::Error for unreadable / non-image input.
class ImageUploadConversionService
  class ImageTooSmall < StandardError; end

  ROTATED_ORIENTATIONS = [5, 6, 7, 8].freeze

  class << self
    def call(file:, name:)
      converted_image = process_image(file)

      ActiveStorage::Blob.create_and_upload!(
        io: converted_image,
        filename: "#{name.parameterize(separator: '_')}.webp",
        content_type: "image/webp" # we convert all images to this format
      )
    end

    private

    def process_image(file)
      ensure_minimum_dimensions!(file.tempfile.path)

      resize_and_convert_before_storage(file)
    end

    # Reject images that are too small to be useful *before* spending time on
    # the conversion. Checks the display dimensions (EXIF rotation applied).
    def ensure_minimum_dimensions!(path)
      image = ::Vips::Image.new_from_file(path, access: :sequential)
      orientation = begin
        image.get("orientation")
      rescue ::Vips::Error
        1
      end
      width, height = ROTATED_ORIENTATIONS.include?(orientation) ? [image.height, image.width] : [image.width, image.height]

      return if width >= Picture::MIN_PIXEL_WIDTH && height >= Picture::MIN_PIXEL_HEIGHT

      raise ImageTooSmall.new("image is #{width}×#{height}px, the minimum is " \
                              "#{Picture::MIN_PIXEL_WIDTH}×#{Picture::MIN_PIXEL_HEIGHT}px")
    end

    # inspired by: https://vitobotta.com/2020/09/24/resize-and-optimise-images-on-upload-with-activestorage/
    #
    # `resize_to_limit` uses libvips' thumbnail operation, which auto-rotates
    # per EXIF Orientation and only ever downsizes (small images pass through).
    # WebP is lossy here for every source format (PNG/GIF transparency is
    # preserved, animation is not).
    def resize_and_convert_before_storage(file)
      save_options = { quality: Picture.webp_quality }
      save_options[:strip] = true if Picture.strip_metadata?

      ImageProcessing::Vips
        .source(file.tempfile)
        .resize_to_limit(Picture::MAX_PIXEL_WIDTH, Picture::MAX_PIXEL_HEIGHT)
        .convert("webp")
        .saver(**save_options)
        .call!
    end
  end
end
