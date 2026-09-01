# frozen_string_literal: true

module Yui
  # @label Tag
  class TagComponentPreview < ViewComponent::Preview
    # @param label text
    # @param icon select [~, map-pin, bookmark, link]
    # @param removable toggle
    def playground(label: "Ericeira, Portugal", icon: "map-pin", removable: false)
      render Yui::TagComponent.new(label, icon: icon.presence, removable:)
    end

    def plain
      render(Yui::TagComponent.new("beach"))
    end

    def with_icon
      render(Yui::TagComponent.new("Ericeira, Portugal", icon: "map-pin"))
    end

    def as_link
      render(Yui::TagComponent.new("cabo-da-roca", href: "#"))
    end

    def removable
      render(Yui::TagComponent.new("winter", removable: true))
    end
  end
end
