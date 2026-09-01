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

    def text
      @text || content
    end

    slim_template <<~SLIM
      strong.ex-strong = text
    SLIM
  end
end
