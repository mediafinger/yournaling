# frozen_string_literal: true

module Yui
  # The one button. Renders a <button> by default, or an <a role="button">
  # when `href:` is given.
  #
  #   Yui::ButtonComponent.new("Save memory", variant: :primary)
  #   Yui::ButtonComponent.new("Cancel", variant: :ghost, href: "/back")
  #   Yui::ButtonComponent.new("Delete", variant: :danger, icon: "trash")
  #   = render(Yui::ButtonComponent.new(variant: :secondary, size: :lg)) { "Browse" }
  #
  # variant: :primary (default), :secondary, :warning, :danger, :ghost
  # size:    :sm, :md (default), :lg
  class ButtonComponent < BaseComponent
    VARIANTS = %i[primary secondary warning danger ghost].freeze
    SIZES = %i[sm md lg].freeze

    attr_reader :href, :variant, :size, :type, :icon, :trailing_icon, :disabled, :full_width

    def initialize(
      label = nil, href: nil, variant: :primary, size: :md, type: "button",
      icon: nil, trailing_icon: nil, disabled: false, full_width: false
    )
      super()
      @label = label
      @href = href
      @variant = ex_token(variant, allowed: VARIANTS, default: :primary)
      @size = ex_token(size, allowed: SIZES, default: :md)
      @type = type
      @icon = icon.presence
      @trailing_icon = trailing_icon.presence
      @disabled = disabled
      @full_width = full_width
    end

    def label
      @label || content
    end

    def css_class
      ex_class(
        "ex-btn",
        "ex-btn--#{variant}",
        size != :md && "ex-btn--#{size}",
        full_width && "ex-btn--block",
        disabled && href.present? && "ex-btn--disabled",
      )
    end

    def icon_size
      size == :sm ? :sm : :md
    end
  end
end
