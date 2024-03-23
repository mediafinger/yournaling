class MapLinkComponent < ApplicationComponent
  erb_template <<-ERB
    <span class="map_link">
      <%= @link_tag %>
    </span>
  ERB

  def initialize(location:, width:, height:)
    @location = location
    @width = width
    @height = height
  end

  def before_render
    @image_tag = image_tag(
      @location.map(width: @width, height: @height), size: "#{@width}x#{@height}", alt: @location.address)

    @link_tag = link_to(@image_tag, @location.gmaps_coordinates_url, target: "_blank", rel: "noopener")
  end
end
