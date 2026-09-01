# frozen_string_literal: true

module Yui
  # @label Headline
  class HeadlineComponentPreview < ViewComponent::Preview
    # @param text text
    # @param level select [1, 2, 3, 4]
    # @param eyebrow text
    # @param align select [left, center]
    # @param display toggle
    def playground(text: "A year on the coast", level: 1, eyebrow: "Chronicle", align: :left, display: false)
      render Yui::HeadlineComponent.new(text, level: level.to_i, eyebrow: eyebrow.presence, align:, display:)
    end

    def level_1
      render(Yui::HeadlineComponent.new("A year on the coast", level: 1))
    end

    def level_2
      render(Yui::HeadlineComponent.new("Everything we kept", level: 2))
    end

    def level_3
      render(Yui::HeadlineComponent.new("The northern beach at dusk", level: 3))
    end

    def level_4
      render(Yui::HeadlineComponent.new("Field notes, week four", level: 4))
    end

    def with_eyebrow
      render(Yui::HeadlineComponent.new("A year on the coast", level: 1, eyebrow: "Chronicle"))
    end

    def display
      render(Yui::HeadlineComponent.new("Kept for good", level: 1, display: true))
    end
  end
end
