# frozen_string_literal: true

module Yui
  # The general-purpose card surface. Compose it with slots:
  #
  #   = render(Yui::CardComponent.new(variant: :elevated)) do |card|
  #     - card.with_media do
  #       = image_tag(...)
  #     - card.with_header do
  #       = render(Yui::HeadlineComponent.new("Northern beach", level: 3))
  #     p The tide took the rest.
  #     - card.with_footer do
  #       = render(Yui::ButtonComponent.new("Open", size: :sm, variant: :secondary))
  #
  # variant: :default, :elevated, :outline, :sunken
  # accent:  a colour token name (e.g. "accent", "gold", "success") → left border
  # padding: :sm, :md (default), :lg
  # href:    makes the whole card a link
  # class:   extra class(es) for the card root — used by composed cards
  #          (`Yui::MemoryCardComponent` passes "ex-memory-card")
  class CardComponent < BaseComponent
    VARIANTS = %i[default elevated outline sunken].freeze
    PADDINGS = %i[sm md lg].freeze

    renders_one :media
    renders_one :header
    renders_one :footer

    attr_reader :variant, :accent, :padding, :href, :interactive, :extra_class

    def initialize(variant: :default, accent: nil, padding: :md, href: nil, interactive: false, class: nil)
      super()
      @variant = ex_token(variant, allowed: VARIANTS, default: :default)
      @accent = accent.presence
      @padding = ex_token(padding, allowed: PADDINGS, default: :md)
      @href = href.presence
      @interactive = interactive || href.present?
      @extra_class = binding.local_variable_get(:class).presence
    end

    def css_class
      ex_class(
        "ex-card",
        variant != :default && "ex-card--#{variant}",
        padding != :md && "ex-card--pad-#{padding}",
        accent && "ex-card--accent",
        interactive && "ex-card--interactive",
        extra_class,
      )
    end

    def inline_style
      "--ex-card-accent: var(--ex-#{accent})" if accent
    end

    def wrapper_tag
      href ? :a : :article
    end
  end
end
