# frozen_string_literal: true

module Yui
  # Inline quoted / italic phrase — semantic <em>, set in the serif face.
  #
  #   Yui::QuoteComponent.new("the light was impossible")
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
