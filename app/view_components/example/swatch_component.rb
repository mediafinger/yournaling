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
  end
end
