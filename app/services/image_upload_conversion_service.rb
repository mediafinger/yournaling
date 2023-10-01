# NOTE: this service need the libvips library installed, to convert images
# installing optional dependencies for JPG, EXIF, ... might be necessary as well
# https://github.com/libvips/libvips#optional-dependencies
#
class ImageUploadConversionService
  class << self
    def call(file:, name:)
      converted_image = process_image(file)

      ActiveStorage::Blob.create_and_upload!(
        io: converted_image,
        filename: "#{name.parameterize(separator: '_')}.webp", # what happens with duplicate names?
        content_type: "image/webp" # we convert all images to this format
      )
    end

    private

    # calls resize_and_convert_before_storage(file) to downsize the image and convert to webp
    # returns the new file (not the original one)
    # with updated filename and content_type to indicate the new file type "image/webp"
    def process_image(file)
      # TODO: validate uploaded file first!
      # is image?
      # Pictures::ALLOWED_CONTENT_TYPES
      # file size MByte (min..max)
      # file size Pixels (min..max)
      # landscape vs portrait or square?

      # original_extension = File.extname(file.tempfile)
      # updated_filename = file.original_filename.gsub(/(#{original_extension})$/, ".webp")
      # new_file = file.dup
      # new_file.content_type = "image/webp"

      resize_and_convert_before_storage(file)
    end

    # NOTE
    # resizes (downsizes) uploaded image to max of 4000x3000 pixels
    # converts to webp
    # does not (yet) strip EXIF data (e.g. GPS coordinates, date/time, camera model, dimensions, etc.)
    # sets quality to 90%
    # and only then the file is saved to disk
    # inspired by: https://vitobotta.com/2020/09/24/resize-and-optimise-images-on-upload-with-activestorage/
    #
    def resize_and_convert_before_storage(file)
      # TODO: check file size in pixels and fail when too small? e.g. less than 800x600 pixels
      # TODO: check conversion to WebP for all images - lossless for PNG and GIF, lossy for JPEG and TIFF ?
      #       or at least keep transparency for PNGs and GIFs? (but no animated GIFs)
      # TODO: only replace when downsized is smaller than original ?! Would need checks on pixel size as well as file size.

      ImageProcessing::Vips.source(file.tempfile).resize_to_limit(4000, 3000).convert("webp").saver(quality: 90).call!
    end
  end
end
