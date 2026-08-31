# frozen_string_literal: true

module Example
  # @label Quote
  class QuoteComponentPreview < ViewComponent::Preview
    # @param text text
    def playground(text: "the light was impossible")
      render Example::QuoteComponent.new(text)
    end
  end
end
