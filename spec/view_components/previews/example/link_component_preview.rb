# frozen_string_literal: true

module Example
  # @label Link
  class LinkComponentPreview < ViewComponent::Preview
    # @param text text
    # @param variant select [default, muted, standalone]
    # @param external toggle
    def playground(text: "Read the chronicle", variant: :default, external: false)
      render Example::LinkComponent.new(text, href: "#", variant:, external:)
    end

    def default
      render(Example::LinkComponent.new("full chronicle", href: "#"))
    end

    def muted
      render(Example::LinkComponent.new("Back to all experiences", href: "#", variant: :muted))
    end

    # Trailing arrow that nudges on hover.
    def standalone
      render(Example::LinkComponent.new("See every memory", href: "#", variant: :standalone))
    end

    def external
      render(Example::LinkComponent.new("mediafinger.com", href: "https://mediafinger.com", external: true))
    end
  end
end
