# frozen_string_literal: true

module Yui
  # Compact status/label badge.
  #
  #   Yui::BadgeComponent.new("Published", variant: :success)
  #   Yui::BadgeComponent.new("Draft", variant: :warning, dot: true)
  #
  # variant: :neutral (default), :accent, :success, :warning, :danger, :info, :gold
  class BadgeComponent < BaseComponent
    VARIANTS = %i[neutral accent success warning danger info gold].freeze

    attr_reader :variant, :dot, :icon

    def initialize(label = nil, variant: :neutral, dot: false, icon: nil)
      super()
      @label = label
      @variant = yui_token(variant, allowed: VARIANTS, default: :neutral)
      @dot = dot
      @icon = icon.presence
    end

    def label
      @label || content
    end

    def css_class
      yui_class("yui-badge", variant != :neutral && "yui-badge--#{variant}")
    end
  end
end
