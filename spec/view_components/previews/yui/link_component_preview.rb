# frozen_string_literal: true

module Yui
  # @label Link
  class LinkComponentPreview < ViewComponent::Preview
    # @param text text
    # @param variant select [default, muted, standalone]
    # @param external toggle
    def playground(text: "Read the chronicle", variant: :default, external: false)
      render Yui::LinkComponent.new(text, href: "#", variant:, external:)
    end

    def default
      render(Yui::LinkComponent.new("full chronicle", href: "#"))
    end

    def muted
      render(Yui::LinkComponent.new("Back to all experiences", href: "#", variant: :muted))
    end

    # Trailing arrow that nudges on hover.
    def standalone
      render(Yui::LinkComponent.new("See every memory", href: "#", variant: :standalone))
    end

    def external
      render(Yui::LinkComponent.new("mediafinger.com", href: "https://mediafinger.com", external: true))
    end
  end
end
