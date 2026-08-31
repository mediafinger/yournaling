# frozen_string_literal: true

module Example
  # Standalone form label with an optional required/optional marker.
  #
  #   Example::LabelComponent.new("Title", for: "memory_title", required: true)
  #   Example::LabelComponent.new("Notes", for: "memory_notes", optional: true)
  class LabelComponent < BaseComponent
    attr_reader :text, :for_id, :required, :optional

    def initialize(text = nil, for: nil, required: false, optional: false)
      super()
      @text = text
      @for_id = binding.local_variable_get(:for)
      @required = required
      @optional = optional
    end

    def label_text
      @text || content
    end

    slim_template <<~SLIM
      label.ex-label for=for_id
        = label_text
        - if required
          span.ex-label__required aria-hidden="true"
            | *
        - elsif optional
          span.ex-label__optional
            | (optional)
    SLIM
  end
end
