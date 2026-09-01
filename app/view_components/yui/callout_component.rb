# frozen_string_literal: true

module Yui
  # A bordered, tinted notice for inline guidance, confirmations and warnings.
  #
  #   = render(Yui::CalloutComponent.new(variant: :success, title: "Memory saved")) do
  #     | It now appears in this experience's timeline.
  #
  # variant: :info (default), :success, :warning, :danger
  class CalloutComponent < BaseComponent
    VARIANTS = %i[info success warning danger].freeze
    ICONS = {
      info: "info", success: "check-circle", warning: "triangle-alert", danger: "triangle-alert"
    }.freeze

    attr_reader :variant, :title

    def initialize(variant: :info, title: nil)
      super()
      @variant = ex_token(variant, allowed: VARIANTS, default: :info)
      @title = title.presence
    end

    def css_class
      ex_class("ex-callout", variant != :info && "ex-callout--#{variant}")
    end
  end
end
