# frozen_string_literal: true

module Yui
  # Horizontal rule. Plain by default, or with a centered uppercase label.
  #
  #   Yui::DividerComponent.new
  #   Yui::DividerComponent.new("Later that year")
  class DividerComponent < BaseComponent
    def initialize(label = nil)
      super()
      @label = label.presence
    end

    attr_reader :label
  end
end
