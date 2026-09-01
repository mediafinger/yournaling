# frozen_string_literal: true

module Yui
  # @label Emphasis
  class EmphasisComponentPreview < ViewComponent::Preview
    # @param text text
    def playground(text: "kept for good")
      render Yui::EmphasisComponent.new(text)
    end
  end
end
