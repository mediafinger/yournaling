# frozen_string_literal: true

module Example
  # A titled section on the showcase page.
  #
  #   = render(Example::SectionComponent.new(number: "02", title: "Typography",
  #            anchor: "typography", description: "Fraunces for display, Inter for UI.")) do
  #     ...
  class SectionComponent < Yui::BaseComponent
    attr_reader :number, :title, :anchor, :description

    def initialize(title:, anchor:, number: nil, description: nil)
      super()
      @title = title
      @anchor = anchor
      @number = number
      @description = description.presence
    end

    slim_template <<~'SLIM'
      section.ex-section id=anchor
        .ex-container
          header.ex-section__head
            - if number
              span.ex-section__number = "#{number} —"
            = render(Yui::HeadlineComponent.new(title, level: 2))
            - if description
              p.ex-section__desc = description
          = content
    SLIM
  end
end
