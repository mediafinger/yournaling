# frozen_string_literal: true

module Example
  # Inline quoted / italic phrase — semantic <em>, set in the serif face.
  #
  #   Example::QuoteComponent.new("the light was impossible")
  class QuoteComponent < BaseComponent
    def initialize(text = nil)
      super()
      @text = text
    end

    def text
      @text || content
    end

    slim_template <<~SLIM
      em.ex-quote = text
    SLIM
  end
end
