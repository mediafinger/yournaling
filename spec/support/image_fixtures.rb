# frozen_string_literal: true

# Test images live in spec/support/images/. They were all derived from the one
# real smartphone photo (spec/support/macbookair_stickered.jpg — a Google
# Pixel 4a JPEG taken 2022-04-12 in Cologne with full GPS EXIF):
#
#   portrait_gps.jpg       physically rotated 90° (genuine portrait, EXIF kept)
#   square_gps.jpg         centre 1000×1000 crop (EXIF kept)
#   exif_orientation_6.jpg landscape pixels + EXIF Orientation=6 (display: portrait)
#   no_exif.jpg            all metadata stripped ("anonymous" upload)
#   plain.png              800px PNG, no EXIF (format without GPS support)
#   tiny.jpg               160×111 px, below the minimum size, no EXIF
#
# Regenerate: see README_PICTURES.md ("Test fixtures").
module ImageFixtures
  DIR = Rails.root.join("spec/support/images")

  # The original, unmodified photo — the canonical "rich EXIF" fixture.
  ORIGINAL = Rails.root.join("spec/support/macbookair_stickered.jpg")

  # EXIF ground truth for ORIGINAL and its derivatives.
  EXIF_LATITUDE = 50.93371666666667
  EXIF_LONGITUDE = 6.940847222222222
  EXIF_ALTITUDE = 97.8
  EXIF_TAKEN_AT = Time.new(2022, 4, 12, 20, 18, 12, "+02:00")

  module_function

  def path(name)
    name.to_s.include?("/") || name.to_s.end_with?(".jpg", ".png") ? DIR.join(name) : DIR.join("#{name}.jpg")
  end

  # An ActionDispatch-style uploaded file for request specs / services.
  def upload(name, content_type: "image/jpeg")
    file = name == :original ? ORIGINAL : path(name)
    Rack::Test::UploadedFile.new(file, content_type)
  end
end
