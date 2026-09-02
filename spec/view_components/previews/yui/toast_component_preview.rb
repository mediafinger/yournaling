# frozen_string_literal: true

module Yui
  # @label Toast
  class ToastComponentPreview < ViewComponent::Preview
    # @param message text
    # @param variant select [info, success, warning, danger]
    def playground(message: "Memory saved to The Coast Year", variant: :success)
      render_with_template(locals: { message:, variant: })
    end

    def success
      render(Yui::ToastComponent.new("Chronicle was successfully created.", variant: :success, delay: 0))
    end

    def danger
      render(Yui::ToastComponent.new("That address looks incomplete.", variant: :danger, delay: 0))
    end
  end
end
