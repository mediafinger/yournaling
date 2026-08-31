# frozen_string_literal: true

module Example
  # @label Card
  class CardComponentPreview < ViewComponent::Preview
    # @param variant select [default, elevated, outline, sunken]
    # @param accent select [~, accent, gold, success]
    # @param padding select [sm, md, lg]
    def playground(variant: :elevated, accent: nil, padding: :md)
      render(Example::CardComponent.new(variant:, accent: accent.presence, padding:)) do
        "A card surface. Compose it with media / header / footer slots."
      end
    end

    def default
      render(Example::CardComponent.new) { "A hairline border on a plain surface." }
    end

    def elevated
      render(Example::CardComponent.new(variant: :elevated)) { "Borderless, lifted with a soft warm shadow." }
    end

    def with_slots
      render_with_template
    end

    # Whole card becomes an <a>.
    def as_link
      render(Example::CardComponent.new(variant: :elevated, href: "#")) { "The whole card is a link." }
    end
  end
end
