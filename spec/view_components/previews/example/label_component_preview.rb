# frozen_string_literal: true

module Example
  # @label Label
  class LabelComponentPreview < ViewComponent::Preview
    # @param text text
    # @param required toggle
    # @param optional toggle
    def playground(text: "Title", required: false, optional: false)
      render Example::LabelComponent.new(text, for: "demo", required:, optional:)
    end

    def plain
      render(Example::LabelComponent.new("Title", for: "demo"))
    end

    def required
      render(Example::LabelComponent.new("Title", for: "demo", required: true))
    end

    def optional
      render(Example::LabelComponent.new("Notes", for: "demo", optional: true))
    end
  end
end
