# frozen_string_literal: true

module Example
  # A single colour swatch for the palette documentation.
  #
  #   Example::SwatchComponent.new(name: "Accent", token: "--ex-accent", value: "#b5541e")
  class SwatchComponent < BaseComponent
    attr_reader :name, :token, :value

    def initialize(name:, token:, value: nil)
      super()
      @name = name
      @token = token
      @value = value
    end

    slim_template <<~'SLIM'
      .ex-swatch
        .ex-swatch__chip style="background-color: var(#{token})"
        .ex-swatch__meta
          span.ex-swatch__name = name
          span.ex-swatch__value = value || token
    SLIM
  end
end
