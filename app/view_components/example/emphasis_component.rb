# frozen_string_literal: true

module Example
  # Inline emphasis — semantic <strong>, styled as a confident bold.
  #
  #   Example::EmphasisComponent.new("kept for good")
  #   = render(Example::EmphasisComponent.new) { "matters" }
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
