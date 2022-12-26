# See config/storage.yml for more config
#
# ActiveStorage is used through the model:
# class Picture
#   has_one_attached :file
#   file.variant(...)

Rails.application.configure do
  # Store files locally under tmp/storage
  config.active_storage.service = AppConf.production_env ? :amazon_s3 : :dev

  # Avoid expensive external existence checks
  config.active_storage.track_variants = true

  # Resize images using vips, aternative is :mini_magick
  config.active_storage.variant_processor = :vips
end
