# frozen_string_literal: true

module Yui
  # @label Field
  class FieldComponentPreview < ViewComponent::Preview
    # @param label text
    # @param as select [input, textarea, select]
    # @param type select [text, email, password, number, url]
    # @param placeholder text
    # @param hint text
    # @param error text
    # @param required toggle
    # @param disabled toggle
    def playground(
      label: "Title", as: :input, type: "text", placeholder: "A short name for this memory",
      hint: "Keep it under a sentence.", error: nil, required: true, disabled: false
    )
      render Yui::FieldComponent.new(
        label:, name: "memory[title]", as:, type:, placeholder: placeholder.presence,
        hint: hint.presence, error: error.presence, required:, disabled:,
        options: [%w[Private private], %w[Team team], %w[Public public]]
      )
    end

    def text_input
      render(Yui::FieldComponent.new(label: "Title", name: "memory[title]", required: true,
        placeholder: "A short name for this memory"))
    end

    def textarea
      render(Yui::FieldComponent.new(label: "Notes", name: "memory[notes]", as: :textarea,
        hint: "Markdown is supported."))
    end

    def select
      render(Yui::FieldComponent.new(label: "Visibility", name: "memory[visibility]", as: :select, value: "team",
        options: [["Private — only me", "private"], ["Team", "team"],
                  ["Public", "public"]]))
    end

    def with_error
      render(Yui::FieldComponent.new(label: "Email", name: "email", type: "email", value: "andy@",
        error: "That address looks incomplete."))
    end

    def disabled
      render(Yui::FieldComponent.new(label: "Location", name: "loc", disabled: true, value: "Locked while syncing…"))
    end
  end
end
