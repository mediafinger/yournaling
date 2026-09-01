# frozen_string_literal: true

module Yui
  # Pill-shaped tag / chip. Renders an <a> when `href:` is given, otherwise a
  # <span>. Set `removable: true` for a trailing ✕ affordance (presentational).
  #
  #   Yui::TagComponent.new("Lisbon", icon: "map-pin", href: "/locations/lisbon")
  #   Yui::TagComponent.new("beach", removable: true)
  class TagComponent < BaseComponent
    attr_reader :href, :icon, :removable

    def initialize(label = nil, href: nil, icon: nil, removable: false)
      super()
      @label = label
      @href = href
      @icon = icon.presence
      @removable = removable
    end

    def label
      @label || content
    end
  end
end
