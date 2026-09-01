# frozen_string_literal: true

module Yui
  # Standalone form label with an optional required/optional marker.
  #
  #   Yui::LabelComponent.new("Title", for: "memory_title", required: true)
  #   Yui::LabelComponent.new("Notes", for: "memory_notes", optional: true)
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
  end
end
