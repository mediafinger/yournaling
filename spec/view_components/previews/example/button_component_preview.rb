# frozen_string_literal: true

module Example
  # @label Button
  class ButtonComponentPreview < ViewComponent::Preview
    # @param label text
    # @param variant select [primary, secondary, warning, danger, ghost]
    # @param size select [sm, md, lg]
    # @param icon select [~, plus, arrow-right, trash, search, pencil]
    # @param trailing_icon select [~, arrow-right, arrow-up-right, chevron-down]
    # @param disabled toggle
    # @param full_width toggle
    def playground(
      label: "Save memory", variant: :primary, size: :md,
      icon: nil, trailing_icon: nil, disabled: false, full_width: false
    )
      render Example::ButtonComponent.new(
        label, variant:, size:, icon: icon.presence, trailing_icon: trailing_icon.presence, disabled:, full_width:
      )
    end

    def primary
      render(Example::ButtonComponent.new("Save memory"))
    end

    def secondary
      render(Example::ButtonComponent.new("Cancel", variant: :secondary))
    end

    def danger
      render(Example::ButtonComponent.new("Delete", variant: :danger, icon: "trash"))
    end

    def ghost
      render(Example::ButtonComponent.new("Skip", variant: :ghost))
    end

    # Renders <a role="button"> rather than <button>.
    def as_link
      render(Example::ButtonComponent.new("Back to browse", href: "#", variant: :ghost, trailing_icon: "arrow-up-right"))
    end

    def disabled
      render(Example::ButtonComponent.new("Unavailable", disabled: true))
    end
  end
end
