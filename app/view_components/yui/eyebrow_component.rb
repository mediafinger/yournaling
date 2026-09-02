# frozen_string_literal: true

module Yui
  # Small uppercase kicker/label that sits above a headline.
  #
  #   Yui::EyebrowComponent.new("Chronicle")
  #   = render(Yui::EyebrowComponent.new) { "Since 2019" }
  class EyebrowComponent < BaseComponent
    def initialize(text = nil)
      super()
      @text = text
    end

    # Trivial single-element wrapper — no template (see Yui::BaseComponent).
    def call
      tag.p(@text || content, class: "yui-eyebrow")
    end
  end
end
