# frozen_string_literal: true

module Example
  # A complete form field: label, control, hint and/or error message.
  #
  #   Example::FieldComponent.new(label: "Title", name: "memory[title]", required: true,
  #                               placeholder: "A short name for this memory")
  #   Example::FieldComponent.new(label: "Notes", name: "memory[notes]", as: :textarea,
  #                               hint: "Markdown is supported.")
  #   Example::FieldComponent.new(label: "Visibility", name: "memory[visibility]", as: :select,
  #                               options: [["Private", "private"], ["Team", "team"], ["Public", "public"]],
  #                               value: "team")
  #   Example::FieldComponent.new(label: "Email", name: "email", type: "email",
  #                               error: "That address looks incomplete.")
  #
  # as:   :input (default), :textarea, :select
  # type: any HTML input type (used when as: :input)
  class FieldComponent < BaseComponent
    KINDS = %i[input textarea select].freeze

    attr_reader :label, :name, :kind, :type, :value, :placeholder, :hint, :error,
      :required, :disabled, :options, :rows

    def initialize(
      label:, name:, as: :input, type: "text", value: nil, placeholder: nil,
      hint: nil, error: nil, required: false, disabled: false, options: [], rows: 4
    )
      super()
      @label = label
      @name = name
      @kind = ex_token(as, allowed: KINDS, default: :input)
      @type = type
      @value = value
      @placeholder = placeholder
      @hint = hint.presence
      @error = error.presence
      @required = required
      @disabled = disabled
      @options = options
      @rows = rows
    end

    def field_id
      @field_id ||= "ex-#{name.to_s.gsub(/[^a-z0-9]+/i, '-').gsub(/(^-|-$)/, '')}"
    end

    def invalid?
      error.present?
    end

    # ARIA needs the string "true", not a boolean attribute.
    def aria_invalid
      "true" if invalid?
    end

    def described_by
      ids = []
      ids << "#{field_id}-error" if invalid?
      ids << "#{field_id}-hint" if hint.present?
      ids.join(" ").presence
    end

    def wrapper_class
      ex_class("ex-field", invalid? && "ex-field--invalid")
    end
  end
end
