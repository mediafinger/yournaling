# frozen_string_literal: true

module Example
  # Small uppercase kicker/label that sits above a headline.
  #
  #   Example::EyebrowComponent.new("Chronicle")
  #   = render(Example::EyebrowComponent.new) { "Since 2019" }
  class EyebrowComponent < BaseComponent
    def initialize(text = nil)
      super()
      @text = text
    end

    def text
      @text || content
    end

    slim_template <<~SLIM
      p.ex-eyebrow = text
    SLIM
  end
end
