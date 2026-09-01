# frozen_string_literal: true

module Yui
  # One item in a Yui::Navbar group — an `<li>` wrapping a link.
  #
  #   Yui::NavItemComponent.new("Search", href: "/search", active: on_search?)
  #   Yui::NavItemComponent.new("+ New", href: "/memories/new", variant: :cta)
  #
  # variant: :link (default) or :cta (the filled call-to-action treatment,
  # also used for the currently-active section). `active: true` marks the
  # current page (`aria-current="page"` + the active style).
  class NavItemComponent < BaseComponent
    VARIANTS = %i[link cta].freeze

    def initialize(label = nil, href:, active: false, variant: :link, data: {})
      super()
      @label = label
      @href = href
      @active = active
      @variant = ex_token(variant, allowed: VARIANTS, default: :link)
      @data = data
    end

    def call
      tag.li(class: "ex-navbar__item") do
        link_to(@label || content, @href, class: link_class, aria: { current: (@active ? "page" : nil) }, data: @data)
      end
    end

    private

    def link_class
      ex_class("ex-nav-item", (@variant == :cta || @active) && "ex-nav-item--strong", @active && "ex-nav-item--active")
    end
  end
end
