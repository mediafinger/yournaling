# frozen_string_literal: true

module Example
  # @label Avatar
  class AvatarComponentPreview < ViewComponent::Preview
    # @param name text
    # @param size select [sm, md, lg, xl]
    def playground(name: "Andreas Finger", size: :md)
      render Example::AvatarComponent.new(name:, size:)
    end

    # Initials fallback when no image is given.
    def initials
      render(Example::AvatarComponent.new(name: "Mira Kessler"))
    end

    def sizes
      render_with_template
    end
  end
end
