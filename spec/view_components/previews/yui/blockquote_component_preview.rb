# frozen_string_literal: true

module Yui
  # @label Blockquote
  class BlockquoteComponentPreview < ViewComponent::Preview
    QUOTE = "We travel to lose ourselves; we keep a journal to find ourselves again."

    # @param quote textarea
    # @param cite text
    # @param variant select [plain, card]
    def playground(quote: QUOTE, cite: "Field notes, vol. 3", variant: :plain)
      render Yui::BlockquoteComponent.new(quote, cite: cite.presence, variant:)
    end

    def plain
      render(Yui::BlockquoteComponent.new(QUOTE, cite: "Field notes"))
    end

    def card
      render(Yui::BlockquoteComponent.new(QUOTE, cite: "Field notes, vol. 3", variant: :card))
    end

    def without_attribution
      render(Yui::BlockquoteComponent.new(QUOTE))
    end
  end
end
