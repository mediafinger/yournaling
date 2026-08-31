# frozen_string_literal: true

module Example
  # A bordered, tinted notice for inline guidance, confirmations and warnings.
  #
  #   = render(Example::CalloutComponent.new(variant: :success, title: "Memory saved")) do
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

    slim_template <<~SLIM
      div class=css_class role="note"
        .ex-callout__icon
          = render(Example::IconComponent.new(ICONS.fetch(variant)))
        div
          - if title
            p.ex-callout__title = title
          .ex-callout__body
            = content
    SLIM
  end
end
