# frozen_string_literal: true

module Yui
  # @label Divider
  class DividerComponentPreview < ViewComponent::Preview
    # @param label text
    def playground(label: nil)
      render Yui::DividerComponent.new(label.presence)
    end

    def plain
      render(Yui::DividerComponent.new)
    end

    def labeled
      render(Yui::DividerComponent.new("Later that year"))
    end
  end
end
