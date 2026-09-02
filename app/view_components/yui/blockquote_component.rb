# frozen_string_literal: true

module Yui
  # A pulled quotation with optional attribution.
  #
  #   Yui::BlockquoteComponent.new("We travel to lose ourselves; we journal to find ourselves.", cite: "A. Finger")
  #   = render(Yui::BlockquoteComponent.new(cite: "Field notes")) { "The tide took the rest." }
  #
  # `variant: :card` gives it a filled, bordered treatment.
  class BlockquoteComponent < BaseComponent
    VARIANTS = %i[plain card].freeze

    attr_reader :cite, :variant, :dom_id

    def initialize(quote = nil, cite: nil, variant: :plain, id: nil)
      super()
      @quote = quote
      @cite = cite.presence
      @variant = yui_token(variant, allowed: VARIANTS, default: :plain)
      @dom_id = id.presence
    end

    def quote
      @quote || content
    end

    def css_class
      yui_class("yui-blockquote", variant == :card && "yui-blockquote--card")
    end
  end
end
