# frozen_string_literal: true

module Example
  # Compact status/label badge.
  #
  #   Example::BadgeComponent.new("Published", variant: :success)
  #   Example::BadgeComponent.new("Draft", variant: :warning, dot: true)
  #
  # variant: :neutral (default), :accent, :success, :warning, :danger, :info, :gold
  class BadgeComponent < BaseComponent
    VARIANTS = %i[neutral accent success warning danger info gold].freeze

    attr_reader :variant, :dot, :icon

    def initialize(label = nil, variant: :neutral, dot: false, icon: nil)
      super()
      @label = label
      @variant = ex_token(variant, allowed: VARIANTS, default: :neutral)
      @dot = dot
      @icon = icon.presence
    end

    def label
      @label || content
    end

    def css_class
      ex_class("ex-badge", variant != :neutral && "ex-badge--#{variant}")
    end

    slim_template <<~SLIM
      span class=css_class
        - if dot
          span.ex-badge__dot
        - elsif icon
          = render(Example::IconComponent.new(icon, size: :sm))
        = label
    SLIM
  end
end
