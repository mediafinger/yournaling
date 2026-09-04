# frozen_string_literal: true

require "exifr/jpeg"
require "exifr/tiff"

module Images
  # Reads pixel geometry (via libvips) and EXIF metadata (via the exifr gem)
  # from an uploaded image. Never raises: an unreadable file or a format
  # without EXIF simply yields nil fields, so upload flows can call it
  # unconditionally.
  #
  #   meta = Images::MetadataExtractor.call(uploaded_file)   # ActionDispatch::Http::UploadedFile
  #   meta = Images::MetadataExtractor.call("/path/to.jpg")  # path / Pathname / File / Tempfile
  #
  # EXIF (timestamp, GPS, camera) is only read for JPEG and TIFF — the formats
  # that carry it in practice. PNG/WebP/GIF return geometry only.
  module MetadataExtractor
    module_function

    # EXIF orientation values 5..8 store the pixels rotated 90°, so the
    # displayed width/height are the transpose of the stored buffer.
    TRANSPOSED_ORIENTATIONS = [5, 6, 7, 8].freeze

    def call(source)
      path = path_for(source)

      geometry = read_geometry(path)
      exif = read_exif(path, geometry[:content_type])

      Metadata.new(**geometry, **exif)
    end

    def path_for(source)
      return source.path if source.respond_to?(:path) && source.path
      return source.to_path if source.respond_to?(:to_path)

      source.to_s
    end

    def read_geometry(path)
      content_type = Marcel::MimeType.for(Pathname.new(path))
      image = Vips::Image.new_from_file(path.to_s, access: :sequential)

      orientation = vips_orientation(image)
      transposed = TRANSPOSED_ORIENTATIONS.include?(orientation)
      width  = transposed ? image.height : image.width
      height = transposed ? image.width : image.height

      { width:, height:, rotated: transposed, content_type:,
        byte_size: File.size(path), orientation: classify(width, height) }
    rescue Vips::Error, Errno::ENOENT => e
      Rails.logger.warn("Images::MetadataExtractor geometry read failed: #{e.class} #{e.message}")
      { width: nil, height: nil, rotated: false, orientation: nil,
        content_type: content_type, byte_size: (File.size(path) if File.exist?(path)) }
    end

    def vips_orientation(image)
      image.get("orientation")
    rescue Vips::Error
      1
    end

    def classify(width, height)
      return nil if width.nil? || height.nil?
      return :square if width == height

      width > height ? :landscape : :portrait
    end

    def read_exif(path, content_type)
      reader =
        case content_type
        when "image/jpeg" then EXIFR::JPEG
        when "image/tiff" then EXIFR::TIFF
        end
      return blank_exif unless reader

      raw = reader.new(path.to_s)
      return blank_exif unless raw.exif?

      gps = raw.gps

      {
        taken_at: raw.date_time_original || raw.date_time,
        latitude: gps&.latitude,
        longitude: gps&.longitude,
        altitude: gps&.altitude,
        camera_make: raw.make&.to_s&.strip.presence,
        camera_model: raw.model&.to_s&.strip.presence,
      }
    rescue EXIFR::MalformedImage => e
      Rails.logger.warn("Images::MetadataExtractor EXIF read failed: #{e.class} #{e.message}")
      blank_exif
    end

    def blank_exif
      { taken_at: nil, latitude: nil, longitude: nil, altitude: nil,
        camera_make: nil, camera_model: nil }
    end
  end
end
