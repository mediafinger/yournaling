# frozen_string_literal: true

module Example
  # Pill-shaped tag / chip. Renders an <a> when `href:` is given, otherwise a
  # <span>. Set `removable: true` for a trailing ✕ affordance (presentational).
  #
  #   Example::TagComponent.new("Lisbon", icon: "map-pin", href: "/locations/lisbon")
  #   Example::TagComponent.new("beach", removable: true)
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

    slim_template <<~'SLIM'
      - if href.present?
        = link_to(href, class: "ex-tag") do
          - if icon
            = render(Example::IconComponent.new(icon, size: :sm))
          = label
      - else
        span.ex-tag
          - if icon
            = render(Example::IconComponent.new(icon, size: :sm))
          = label
          - if removable
            button.ex-tag__remove type="button" aria-label="Remove #{label}"
              = render(Example::IconComponent.new("x", size: :sm))
    SLIM
  end
end
