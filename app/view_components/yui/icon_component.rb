# frozen_string_literal: true

module Yui
  # Inline SVG icon from a small curated, stroke-based set (24×24, 1.75 stroke).
  #
  #   Yui::IconComponent.new(:calendar)
  #   Yui::IconComponent.new("map-pin", size: :lg, label: "Location")
  #
  # `size:` accepts :sm, :md (default), :lg. Provide `label:` for a meaningful
  # icon (renders role="img" + <title>); omit it for decorative icons
  # (renders aria-hidden="true").
  class IconComponent < BaseComponent
    SIZES = %i[sm md lg].freeze

    # Each entry is the inner markup of a `0 0 24 24` viewBox, stroked with
    # currentColor. Keep them alphabetised.
    PATHS = {
      "arrow-right" => '<path d="M5 12h14"/><path d="m13 6 6 6-6 6"/>',
      "arrow-up-right" => '<path d="M7 17 17 7"/><path d="M8 7h9v9"/>',
      "bell" => '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/>',
      "book" => '<path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/>' \
                '<path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2Z"/>',
      "bookmark" => '<path d="M19 21l-7-4.5L5 21V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2Z"/>',
      "calendar" => '<rect x="3" y="4.5" width="18" height="17" rx="2.5"/><path d="M3 9.5h18"/>' \
                    '<path d="M8 2.5v4"/><path d="M16 2.5v4"/>',
      "camera" => '<path d="M4 8a2 2 0 0 1 2-2h1.5l1.2-1.8A1 1 0 0 1 9.5 4h5a1 1 0 0 1 .8.4L16.5 6H18a2 2 0 0 1 2 2v9' \
                  'a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2Z"/><circle cx="12" cy="12.5" r="3.2"/>',
      "check" => '<path d="M20 6 9 17l-5-5"/>',
      "check-circle" => '<path d="M21.5 11.1V12a9.5 9.5 0 1 1-5.6-8.7"/><path d="m9 12 2.5 2.5L22 4.5"/>',
      "chevron-down" => '<path d="m6 9 6 6 6-6"/>',
      "chevron-left" => '<path d="m15 6-6 6 6 6"/>',
      "chevron-right" => '<path d="m9 6 6 6-6 6"/>',
      "clock" => '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3.5 2"/>',
      "compass" => '<circle cx="12" cy="12" r="9"/><path d="m15.5 8.5-2 5-5 2 2-5Z"/>',
      "feather" => '<path d="M20 12a8 8 0 0 0-11.3-11.3L4 5.3V20h14.7Z"/>' \
                   '<path d="M16 8 2 22"/><path d="M17.5 15H9"/>',
      "globe" => '<circle cx="12" cy="12" r="9"/><path d="M3 12h18"/>' \
                 '<path d="M12 3a15 15 0 0 1 4 9 15 15 0 0 1-4 9 15 15 0 0 1-4-9 15 15 0 0 1 4-9Z"/>',
      "heart" => '<path d="M20.8 5.6a5.2 5.2 0 0 0-8.8-2A5.2 5.2 0 0 0 3.2 5.6c-1.8 3 .3 7 8.8 12.9 ' \
                 '8.5-5.9 10.6-9.9 8.8-12.9Z"/>',
      "image" => '<rect x="3" y="3.5" width="18" height="17" rx="2.5"/><circle cx="8.5" cy="9" r="1.6"/>' \
                 '<path d="m4 18 5-5 3.5 3.5L16 13l4 4"/>',
      "info" => '<circle cx="12" cy="12" r="9"/><path d="M12 11v5"/><path d="M12 8h.01"/>',
      "link" => '<path d="M10 13a4.5 4.5 0 0 0 6.6.3l2.5-2.5a4.5 4.5 0 0 0-6.4-6.4l-1.4 1.4"/>' \
                '<path d="M14 11a4.5 4.5 0 0 0-6.6-.3L4.9 13.2a4.5 4.5 0 0 0 6.4 6.4l1.4-1.4"/>',
      "lock" => '<rect x="4" y="10.5" width="16" height="11" rx="2.5"/><path d="M8 10.5V7a4 4 0 0 1 8 0v3.5"/>',
      "map-pin" => '<path d="M20 10.5c0 6-8 11.5-8 11.5s-8-5.5-8-11.5a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10.5" r="2.8"/>',
      "moon" => '<path d="M21 12.8A8.5 8.5 0 1 1 11.2 3a6.5 6.5 0 0 0 9.8 9.8Z"/>',
      "pencil" => '<path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4Z"/>',
      "plus" => '<path d="M12 5v14"/><path d="M5 12h14"/>',
      "quote" => '<path d="M9 7c-2.5 1.2-4 3.7-4 6.7V19h6v-6H7c0-2 .8-3.4 2.7-4.4Z"/>' \
                 '<path d="M19 7c-2.5 1.2-4 3.7-4 6.7V19h6v-6h-4c0-2 .8-3.4 2.7-4.4Z"/>',
      "search" => '<circle cx="11" cy="11" r="7"/><path d="m20 20-4-4"/>',
      "sparkle" => '<path d="M12 3.5 13.8 9 19 10.8 13.8 12.6 12 18l-1.8-5.4L5 10.8 10.2 9Z"/>' \
                   '<path d="M19 4v3"/><path d="M20.5 5.5h-3"/>',
      "star" => '<path d="m12 3.5 2.6 5.3 5.9.9-4.3 4.1 1 5.8-5.2-2.7-5.2 2.7 1-5.8-4.3-4.1 5.9-.9Z"/>',
      "sun" => '<circle cx="12" cy="12" r="4"/><path d="M12 2v2.5"/><path d="M12 19.5V22"/>' \
               '<path d="m4.9 4.9 1.8 1.8"/><path d="m17.3 17.3 1.8 1.8"/><path d="M2 12h2.5"/>' \
               '<path d="M19.5 12H22"/><path d="m4.9 19.1 1.8-1.8"/><path d="m17.3 6.7 1.8-1.8"/>',
      "trash" => '<path d="M4 7h16"/><path d="M10 11v6"/><path d="M14 11v6"/>' \
                 '<path d="M6 7l1 13a2 2 0 0 0 2 1.8h6A2 2 0 0 0 17 20l1-13"/>' \
                 '<path d="M9 7V4.5A1.5 1.5 0 0 1 10.5 3h3A1.5 1.5 0 0 1 15 4.5V7"/>',
      "triangle-alert" => '<path d="M10.3 4 2.6 17.5A2 2 0 0 0 4.3 20.5h15.4a2 2 0 0 0 1.7-3L13.7 4a2 2 0 0 0-3.4 0Z"/>' \
                          '<path d="M12 9.5v4"/><path d="M12 17h.01"/>',
      "user" => '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
      "x" => '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>',
    }.freeze

    attr_reader :name, :size, :label

    def initialize(name, size: :md, label: nil)
      super()
      @name = name.to_s
      @size = yui_token(size, allowed: SIZES, default: :md)
      @label = label.presence
    end

    def markup
      PATHS.fetch(name, PATHS["sparkle"])
    end

    def css_class
      yui_class("yui-icon", size != :md && "yui-icon--#{size}")
    end
  end
end
