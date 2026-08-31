# frozen_string_literal: true

module Example
  # @label Emphasis
  class EmphasisComponentPreview < ViewComponent::Preview
    # @param text text
    def playground(text: "kept for good")
      render Example::EmphasisComponent.new(text)
    end
  end
end
