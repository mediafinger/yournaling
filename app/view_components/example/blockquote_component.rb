# frozen_string_literal: true

module Example
  # A pulled quotation with optional attribution.
  #
  #   Example::BlockquoteComponent.new("We travel to lose ourselves; we journal to find ourselves.", cite: "A. Finger")
  #   = render(Example::BlockquoteComponent.new(cite: "Field notes")) { "The tide took the rest." }
  #
  # `variant: :card` gives it a filled, bordered treatment.
  class BlockquoteComponent < BaseComponent
    VARIANTS = %i[plain card].freeze

    attr_reader :cite, :variant

    def initialize(quote = nil, cite: nil, variant: :plain)
      super()
      @quote = quote
      @cite = cite.presence
      @variant = ex_token(variant, allowed: VARIANTS, default: :plain)
    end

    def quote
      @quote || content
    end

    def css_class
      ex_class("ex-blockquote", variant == :card && "ex-blockquote--card")
    end

    slim_template <<~'SLIM'
      figure class=css_class
        blockquote = quote
        - if cite
          figcaption
            | — #{cite}
    SLIM
  end
end
