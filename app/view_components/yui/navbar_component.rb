# frozen_string_literal: true

module Yui
  # The primary navigation bar. Add one or more groups of items; groups are
  # spaced apart (brand left … account right).
  #
  #   = render(Yui::NavbarComponent.new(area: "team")) do |bar|
  #     - bar.with_group do
  #       = render(Yui::NavItemComponent.new("Yournaling", href: root_path))
  #     - bar.with_group do
  #       = render(Yui::NavItemComponent.new("Search", href: search_path, active: on_search?))
  #
  # `area:` ("public" / "team" / "admin") sets `data-area` so the nav picks up
  # the per-area accent. A slotted group may render raw `<li>`s (e.g. a
  # Yui::Menu wrapper) alongside NavItems.
  class NavbarComponent < BaseComponent
    renders_many :groups

    def initialize(area: nil, label: "Primary")
      super()
      @area = area.presence
      @label = label
    end

    attr_reader :area, :label
  end
end
