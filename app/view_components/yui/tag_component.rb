# frozen_string_literal: true

module Yui
  # Pill-shaped tag / chip. Renders an <a> when `href:` is given, otherwise a
  # <span>. Set `removable: true` for a trailing ✕ affordance (presentational).
  #
  #   Yui::TagComponent.new("Lisbon", icon: "map-pin", href: "/locations/lisbon")
  #   Yui::TagComponent.new("beach", removable: true)
  #   Yui::TagComponent.new("example.com", href: url, external: true, id: dom_id(weblink))
  class TagComponent < BaseComponent
    attr_reader :href, :icon, :removable, :external, :dom_id

    def initialize(label = nil, href: nil, icon: nil, removable: false, external: false, id: nil)
      super()
      @label = label
      @href = href
      @icon = icon.presence
      @removable = removable
      @external = external
      @dom_id = id.presence
    end

    def link_options
      opts = { class: "yui-tag", id: dom_id }
      opts[:target] = "_blank" if external
      opts[:rel] = "noopener noreferrer" if external
      opts
    end

    def label
      @label || content
    end
  end
end
