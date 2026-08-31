# frozen_string_literal: true

module Example
  # Horizontal rule. Plain by default, or with a centered uppercase label.
  #
  #   Example::DividerComponent.new
  #   Example::DividerComponent.new("Later that year")
  class DividerComponent < BaseComponent
    def initialize(label = nil)
      super()
      @label = label.presence
    end

    attr_reader :label

    slim_template <<~SLIM
      - if label
        div.ex-divider--labeled role="separator"
          span = label
      - else
        hr.ex-divider
    SLIM
  end
end
