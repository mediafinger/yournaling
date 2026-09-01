# frozen_string_literal: true

module Yui
  # @label Card
  class CardComponentPreview < ViewComponent::Preview
    # @param variant select [default, elevated, outline, sunken]
    # @param accent select [~, accent, gold, success]
    # @param padding select [sm, md, lg]
    def playground(variant: :elevated, accent: nil, padding: :md)
      render(Yui::CardComponent.new(variant:, accent: accent.presence, padding:)) do
        "A card surface. Compose it with media / header / footer slots."
      end
    end

    def default
      render(Yui::CardComponent.new) { "A hairline border on a plain surface." }
    end

    def elevated
      render(Yui::CardComponent.new(variant: :elevated)) { "Borderless, lifted with a soft warm shadow." }
    end

    def with_slots
      render_with_template
    end

    # Whole card becomes an <a>.
    def as_link
      render(Yui::CardComponent.new(variant: :elevated, href: "#")) { "The whole card is a link." }
    end
  end
end
