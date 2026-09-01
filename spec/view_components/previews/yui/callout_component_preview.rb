# frozen_string_literal: true

module Yui
  # @label Callout
  class CalloutComponentPreview < ViewComponent::Preview
    # @param variant select [info, success, warning, danger]
    # @param title text
    # @param body textarea
    def playground(variant: :info, title: "Drafts autosave", body: "This memory is saved every few seconds while you write.")
      render(Yui::CalloutComponent.new(variant:, title: title.presence)) { body }
    end

    def info
      render(Yui::CalloutComponent.new(variant: :info, title: "Drafts autosave")) do
        "This memory is saved to your account every few seconds while you write."
      end
    end

    def success
      render(Yui::CalloutComponent.new(variant: :success, title: "Memory saved")) do
        "It now appears in the timeline for The Coast Year."
      end
    end

    def warning
      render(Yui::CalloutComponent.new(variant: :warning, title: "This experience is still private")) do
        "Only you can see it. Change its visibility to share it with the team."
      end
    end

    def danger
      render(Yui::CalloutComponent.new(variant: :danger, title: "Deleting a chronicle is permanent")) do
        "Its memories stay, but the timeline and its order are lost."
      end
    end
  end
end
