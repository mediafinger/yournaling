# Monkey-patch ActiveStorage::Analyzer::ImageAnalyzer to extract GPS data from JPEGs with the exifr gem
#
# inspiration: https://ledermann.dev/blog/2018/05/15/exif-analyzer-for-active-storage/
#
# might not work with VIPS

# require "exifr/jpeg"

# module ActiveStorage
#   class Analyzer::ImageAnalyzer < Analyzer
#     def metadata
#       read_image do |image|
#         if rotated_image?(image)
#           { width: image.height, height: image.width }
#         else
#           { width: image.width, height: image.height }
#         end.merge(gps_from_exif(image) || {}) # <--- this line is the hook for the monkey-patch
#       end
#     rescue LoadError
#       logger.info "Skipping image analysis because the mini_magick gem isn't installed"
#       {}
#     end

#     private

#     def gps_from_exif(image)
#       logger.info "EXIF: image.class #{image.class}"
#       # logger.info "EXIF: image_type #{image.type}"
#       logger.info "EXIF: image_path #{image.path}"
#       logger.info "EXIF: image_height #{image.height}"
#       logger.info "EXIF: image_width #{image.width}"
#       logger.info "EXIF: original_date #{image.original_date}"
#       logger.info "EXIF: image #{image.inspect}"

#       # return unless image.type == "JPEG"

#       if exif = EXIFR::JPEG.new(image.path).exif
#         if gps = exif.fields[:gps]
#           logger.info "EXIF: gps #{gps.fields}"
#           {
#             latitude:  gps.fields[:gps_latitude].to_f,
#             longitude: gps.fields[:gps_longitude].to_f,
#             # altitude:  gps.fields[:gps_altitude].to_f
#           }
#         end
#       end
#     rescue EXIFR::MalformedImage, EXIFR::MalformedJPEG
#       # no-op
#     end
#   end
# end
