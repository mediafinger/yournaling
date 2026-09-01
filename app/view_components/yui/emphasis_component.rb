# frozen_string_literal: true

module Yui
  # Inline emphasis — semantic <strong>, styled as a confident bold.
  #
  #   Yui::EmphasisComponent.new("kept for good")
  #   = render(Yui::EmphasisComponent.new) { "matters" }
  class EmphasisComponent < BaseComponent
    def initialize(text = nil)
      super()
      @text = text
    end

    # Trivial single-element wrapper — no template (see Yui::BaseComponent).
    def call
      tag.strong(@text || content, class: "ex-strong")
    end
  end
end
