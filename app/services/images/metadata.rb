# frozen_string_literal: true

module Images
  # Immutable result of reading an uploaded image's pixel geometry and EXIF
  # metadata. Produced by Images::MetadataExtractor, consumed when building a
  # Picture (and, from its GPS, a Location).
  #
  # All fields may be nil: a scrubbed smartphone photo carries no EXIF, a PNG
  # never carries GPS, a broken upload has no readable geometry.
  Metadata = Data.define(
    :width,         # Integer — display width in px (EXIF-orientation applied)
    :height,        # Integer — display height in px
    :orientation,   # :landscape | :portrait | :square | nil
    :rotated,       # true when the stored pixels need a 90° turn to display upright
    :content_type,  # "image/jpeg" etc., sniffed from the bytes
    :byte_size,     # Integer — size of the *uploaded* file, before conversion
    :taken_at,      # Time — EXIF DateTimeOriginal (falls back to DateTime)
    :latitude,      # Float — WGS84, from EXIF GPS
    :longitude,     # Float — WGS84, from EXIF GPS
    :altitude,      # Float — metres, from EXIF GPS
    :camera_make,   # String — EXIF Make ("Google")
    :camera_model   # String — EXIF Model ("Pixel 4a")
  ) do
    def landscape? = orientation == :landscape
    def portrait?  = orientation == :portrait
    def square?    = orientation == :square

    # A usable GPS fix needs both axes; altitude is optional.
    def gps? = latitude.present? && longitude.present?

    def coordinates = gps? ? [latitude, longitude] : nil

    def camera
      [camera_make, camera_model].compact.join(" ").presence
    end

    # Attributes to pre-fill a Location from this photo's GPS fix.
    def to_location_attributes
      return {} unless gps?

      { lat: latitude, long: longitude }
    end

    # Attributes to assign straight onto a Picture record.
    def to_picture_attributes
      {
        taken_at:, latitude:, longitude:, altitude:,
        camera_make:, camera_model:,
        image_width: width, image_height: height,
        original_byte_size: byte_size, original_content_type: content_type
      }
    end
  end
end
