# frozen_string_literal: true

module Example
  # A single colour swatch for the palette documentation.
  #
  #   Example::SwatchComponent.new(name: "Accent", token: "--yui-accent", value: "#b5541e")
  class SwatchComponent < Yui::BaseComponent
    attr_reader :name, :token, :value

    def initialize(name:, token:, value: nil)
      super()
      @name = name
      @token = token
      @value = value
    end

    slim_template <<~'SLIM'
      .yui-swatch
        .yui-swatch__chip style="background-color: var(#{token})"
        .yui-swatch__meta
          span.yui-swatch__name = name
          span.yui-swatch__value = value || token
    SLIM
  end
end
