# frozen_string_literal: true

# A static map thumbnail that links out to Google Maps.
#
# When no usable Geoapify key is configured (e.g. local development) the static
# image would 401 and render as a broken image, so we fall back to a plain
# text link to Google Maps instead.
class MapLinkComponent < ApplicationComponent
  def initialize(location:, width:, height:)
    @location = location
    @width = width
    @height = height
  end

  attr_reader :location, :width, :height

  def render?
    location.located?
  end

  def static_map_available?
    key = AppConf.geoapify_api_key

    key.present? && key != "secret_key"
  end

  def image_tag_for_map
    image_tag(
      location.map(width:, height:), size: "#{width}x#{height}", alt: location.address
    )
  end
end
