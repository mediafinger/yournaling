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

    # Trivial single-element wrapper — no template (see Yui::BaseComponent).
    def call
      tag.em(@text || content, class: "ex-quote")
    end
  end
end
