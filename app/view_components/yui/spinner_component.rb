# frozen_string_literal: true

module Yui
  # A CSS-only loading indicator. Pure presentation — no timers, no state.
  #
  #   = render Yui::SpinnerComponent.new
  #   = render Yui::SpinnerComponent.new("Loading more stories…", size: :lg)
  #
  # size: :sm, :md (default), :lg
  class SpinnerComponent < BaseComponent
    SIZES = %i[sm md lg].freeze

    def initialize(label = nil, size: :md)
      super()
      @label = label
      @size = yui_token(size, allowed: SIZES, default: :md)
    end

    attr_reader :label, :size

    def wrapper_class
      yui_class("yui-spinner", size != :md && "yui-spinner--#{size}")
    end

    # Screen-reader text is always present; a visible label is optional.
    def accessible_label
      label.presence || "Loading"
    end
  end
end
