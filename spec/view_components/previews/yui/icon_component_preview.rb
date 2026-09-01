# frozen_string_literal: true

module Yui
  # @label Icon
  class IconComponentPreview < ViewComponent::Preview
    # @param name select ["feather", "book", "calendar", "map-pin", "heart", "star", "quote", "sparkle"]
    # @param size select [sm, md, lg]
    def playground(name: "feather", size: :lg)
      render Yui::IconComponent.new(name, size:)
    end

    # Every icon in the curated set.
    def gallery
      render_with_template
    end

    def sizes
      render_with_template
    end

    # role="img" + <title> for meaningful icons.
    def with_label
      render(Yui::IconComponent.new("map-pin", size: :lg, label: "Location"))
    end
  end
end
