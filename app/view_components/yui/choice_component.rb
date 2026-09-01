# frozen_string_literal: true

module Yui
  # A single checkbox or radio option with a label and optional helper text.
  #
  #   Yui::ChoiceComponent.new("Make this memory public", name: "visibility", type: :checkbox,
  #                                hint: "Anyone with the link can read it.", checked: true)
  #   Yui::ChoiceComponent.new("Team only", name: "visibility", type: :radio, value: "team")
  class ChoiceComponent < BaseComponent
    TYPES = %i[checkbox radio].freeze

    attr_reader :name, :type, :value, :hint, :checked, :disabled

    def initialize(label = nil, name:, type: :checkbox, value: "1", hint: nil, checked: false, disabled: false)
      super()
      @label = label
      @name = name
      @type = ex_token(type, allowed: TYPES, default: :checkbox)
      @value = value
      @hint = hint.presence
      @checked = checked
      @disabled = disabled
    end

    def label_text
      @label || content
    end
  end
end
