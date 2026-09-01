# frozen_string_literal: true

# See config/storage.yml for more config
#
# ActiveStorage is used through the model:
# class Picture
#   has_one_attached :file
#   file.variant(...)

Rails.application.configure do
  # Store files locally under tmp/storage
  config.active_storage.service = if AppConf.production_env
                                    :amazon_s3
                                  elsif AppConf.is?(:environment, :development)
                                    :dev
                                  else
                                    :test
                                  end

  # Avoid expensive external existence checks
  config.active_storage.track_variants = true

  # Resize images using vips, alternative is :mini_magick
  config.active_storage.variant_processor = :vips

  # Proxy files and variants through the application for authenticated delivery
  config.active_storage.resolve_model_to_route = :rails_storage_proxy
end
