# frozen_string_literal: true

module Example
  # @label Eyebrow
  class EyebrowComponentPreview < ViewComponent::Preview
    # @param text text
    def playground(text: "Chronicle")
      render Example::EyebrowComponent.new(text)
    end
  end
end
