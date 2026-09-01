# frozen_string_literal: true

module Yui
  # Text link in the design-language style.
  #
  #   Yui::LinkComponent.new("Read the chronicle", href: "/chronicles/1")
  #   Yui::LinkComponent.new("mediafinger.com", href: "https://mediafinger.com", external: true)
  #   = render(Yui::LinkComponent.new(href: "#", variant: :standalone)) { "See every memory" }
  #
  # Variants: :default, :muted, :standalone (adds a trailing arrow that nudges
  # on hover). `external: true` opens in a new tab and appends an ↗ glyph.
  class LinkComponent < BaseComponent
    VARIANTS = %i[default muted standalone].freeze

    attr_reader :href, :variant, :external

    def initialize(text = nil, href:, variant: :default, external: false)
      super()
      @text = text
      @href = href
      @variant = ex_token(variant, allowed: VARIANTS, default: :default)
      @external = external
    end

    def text
      @text || content
    end

    def css_class
      ex_class("ex-link", variant != :default && "ex-link--#{variant}")
    end

    def link_options
      opts = { class: css_class }
      if external
        opts[:target] = "_blank"
        opts[:rel] = "noopener noreferrer"
      end
      opts
    end

    def trailing_icon
      return "arrow-up-right" if external
      return "arrow-right" if variant == :standalone

      nil
    end

    slim_template <<~SLIM
      = link_to(href, link_options) do
        = text
        - if trailing_icon
          = render(Yui::IconComponent.new(trailing_icon, size: :sm))
    SLIM
  end
end
