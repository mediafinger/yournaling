# frozen_string_literal: true

module Example
  # A demonstration tile used on the showcase page: a hatched frame with a
  # small monospace caption and the live component(s) inside.
  #
  #   = render(Example::SpecimenComponent.new("variant: :primary", center: true)) do
  #     = render(Example::ButtonComponent.new("Save memory"))
  class SpecimenComponent < BaseComponent
    attr_reader :label, :center

    def initialize(label = nil, center: false)
      super()
      @label = label.presence
      @center = center
    end

    def css_class
      ex_class("ex-specimen", center && "ex-specimen--center")
    end

    slim_template <<~SLIM
      .ex-specimen class=("ex-specimen--center" if center)
        - if label
          span.ex-specimen__label = label
        .ex-specimen__row
          = content
    SLIM
  end
end
