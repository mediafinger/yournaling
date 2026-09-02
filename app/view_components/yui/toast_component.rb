# frozen_string_literal: true

module Yui
  # A dismissible flash notification. Rendered into a fixed-position stack by
  # shared_partials/_flash_notifications; auto-dismisses (yui-toast controller).
  #
  #   Yui::ToastComponent.new("Memory saved", variant: :success)
  #
  # variant: :info (default), :success, :warning, :danger
  class ToastComponent < BaseComponent
    VARIANTS = %i[info success warning danger].freeze
    ICONS = { info: "info", success: "check-circle", warning: "triangle-alert", danger: "triangle-alert" }.freeze

    # Rails flash keys → toast variants.
    FLASH_VARIANTS = { "notice" => :success, "success" => :success, "alert" => :danger, "error" => :danger,
                       "warning" => :warning }.freeze

    def initialize(message = nil, variant: :info, delay: 6000)
      super()
      @message = message
      @variant = yui_token(variant, allowed: VARIANTS, default: :info)
      @delay = delay
    end

    attr_reader :variant, :delay

    def message
      @message || content
    end

    def css_class
      yui_class("yui-toast", variant != :info && "yui-toast--#{variant}")
    end
  end
end
