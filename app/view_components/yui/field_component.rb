# frozen_string_literal: true

module Yui
  # A complete form field: label, control, hint and/or error message.
  #
  #   Yui::FieldComponent.new(label: "Title", name: "memory[title]", required: true,
  #                               placeholder: "A short name for this memory")
  #   Yui::FieldComponent.new(label: "Notes", name: "memory[notes]", as: :textarea,
  #                               hint: "Markdown is supported.")
  #   Yui::FieldComponent.new(label: "Visibility", name: "memory[visibility]", as: :select,
  #                               options: [["Private", "private"], ["Team", "team"], ["Public", "public"]],
  #                               value: "team")
  #   Yui::FieldComponent.new(label: "Email", name: "email", type: "email",
  #                               error: "That address looks incomplete.")
  #
  # as:   :input (default), :textarea, :select
  # type: any HTML input type (used when as: :input)
  # autofocus / autocomplete: passed straight through to the control (auth forms
  #   want focus-on-load and password-manager hints like "current-password").
  class FieldComponent < BaseComponent
    KINDS = %i[input textarea select].freeze

    attr_reader :label, :name, :kind, :type, :value, :placeholder, :hint, :error,
      :required, :disabled, :options, :rows, :autofocus, :autocomplete,
      :include_blank, :multiple

    def initialize(
      label:, name:, as: :input, type: "text", value: nil, placeholder: nil,
      hint: nil, error: nil, required: false, disabled: false, options: [], rows: 4,
      autofocus: false, autocomplete: nil, include_blank: false, multiple: false
    )
      super()
      @label = label
      @name = name
      @kind = yui_token(as, allowed: KINDS, default: :input)
      @type = type
      @value = value
      @placeholder = placeholder
      @hint = hint.presence
      @error = error.presence
      @required = required
      @disabled = disabled
      @options = options
      @rows = rows
      @autofocus = autofocus
      @autocomplete = autocomplete.presence
      @include_blank = include_blank
      @multiple = multiple
    end

    # A select's blank first option: `include_blank: true` → an empty label,
    # `include_blank: "— none —"` → that label.
    def blank_option_label
      include_blank == true ? "" : include_blank.to_s
    end

    def option_selected?(option_value)
      if multiple
        Array(value).map(&:to_s).include?(option_value.to_s)
      else
        option_value.to_s == value.to_s
      end
    end

    def field_id
      @field_id ||= "yui-#{name.to_s.gsub(/[^a-z0-9]+/i, '-').gsub(/(^-|-$)/, '')}"
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
      yui_class("yui-field", invalid? && "yui-field--invalid")
    end
  end
end
