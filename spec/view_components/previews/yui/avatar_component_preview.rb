# frozen_string_literal: true

module Yui
  # @label Avatar
  class AvatarComponentPreview < ViewComponent::Preview
    # @param name text
    # @param size select [sm, md, lg, xl]
    def playground(name: "Andreas Finger", size: :md)
      render Yui::AvatarComponent.new(name:, size:)
    end

    # Initials fallback when no image is given.
    def initials
      render(Yui::AvatarComponent.new(name: "Mira Kessler"))
    end

    def sizes
      render_with_template
    end
  end
end
