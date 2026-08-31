# frozen_string_literal: true

module Example
  # @label Divider
  class DividerComponentPreview < ViewComponent::Preview
    # @param label text
    def playground(label: nil)
      render Example::DividerComponent.new(label.presence)
    end

    def plain
      render(Example::DividerComponent.new)
    end

    def labeled
      render(Example::DividerComponent.new("Later that year"))
    end
  end
end
