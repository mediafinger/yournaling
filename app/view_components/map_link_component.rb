# frozen_string_literal: true

# A static map thumbnail that links out to Google Maps.
class MapLinkComponent < ApplicationComponent
  def initialize(location:, width:, height:)
    @location = location
    @width = width
    @height = height
  end

  attr_reader :location, :width, :height

  def image_tag_for_map
    image_tag(
      location.map(width:, height:), size: "#{width}x#{height}", alt: location.address
    )
  end
end
