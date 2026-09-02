# frozen_string_literal: true

module Example
  # A demonstration tile used on the showcase page: a hatched frame with a
  # small monospace caption and the live component(s) inside.
  #
  #   = render(Example::SpecimenComponent.new("variant: :primary", center: true)) do
  #     = render(Yui::ButtonComponent.new("Save memory"))
  class SpecimenComponent < Yui::BaseComponent
    attr_reader :label, :center

    def initialize(label = nil, center: false)
      super()
      @label = label.presence
      @center = center
    end

    def css_class
      yui_class("yui-specimen", center && "yui-specimen--center")
    end
  end
end
