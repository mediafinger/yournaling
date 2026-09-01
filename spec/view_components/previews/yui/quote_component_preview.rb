# frozen_string_literal: true

module Yui
  # @label Quote
  class QuoteComponentPreview < ViewComponent::Preview
    # @param text text
    def playground(text: "the light was impossible")
      render Yui::QuoteComponent.new(text)
    end
  end
end
