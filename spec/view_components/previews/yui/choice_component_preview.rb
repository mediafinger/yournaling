# frozen_string_literal: true

module Yui
  # @label Choice
  class ChoiceComponentPreview < ViewComponent::Preview
    # @param label text
    # @param type select [checkbox, radio]
    # @param hint text
    # @param checked toggle
    # @param disabled toggle
    def playground(label: "Make this memory public", type: :checkbox, hint: "Anyone with the link can read it.",
                   checked: true, disabled: false)
      render Yui::ChoiceComponent.new(label, name: "demo", type:, hint: hint.presence, checked:, disabled:)
    end

    def checkbox
      render(Yui::ChoiceComponent.new("Let the team comment on this memory", name: "comments", type: :checkbox,
        hint: "You can turn this off later.", checked: true))
    end

    def radio
      render(Yui::ChoiceComponent.new("Team only", name: "visibility", type: :radio, value: "team"))
    end

    def disabled
      render(Yui::ChoiceComponent.new("Archived memories", name: "demo", disabled: true))
    end
  end
end
