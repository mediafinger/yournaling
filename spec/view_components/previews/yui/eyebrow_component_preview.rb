# frozen_string_literal: true

module Yui
  # @label Eyebrow
  class EyebrowComponentPreview < ViewComponent::Preview
    # @param text text
    def playground(text: "Chronicle")
      render Yui::EyebrowComponent.new(text)
    end
  end
end
