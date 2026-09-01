# frozen_string_literal: true

module Yui
  # @label Spinner
  class SpinnerComponentPreview < ViewComponent::Preview
    # @param label text
    # @param size select [sm, md, lg]
    def playground(label: "Loading more stories…", size: :md)
      render Yui::SpinnerComponent.new(label.presence, size:)
    end

    def bare
      render(Yui::SpinnerComponent.new)
    end

    def with_label
      render(Yui::SpinnerComponent.new("Loading more stories…"))
    end

    def large
      render(Yui::SpinnerComponent.new("Working…", size: :lg))
    end
  end
end
