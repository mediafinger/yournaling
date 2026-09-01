# frozen_string_literal: true

module Yui
  # @label Nav item
  class NavItemComponentPreview < ViewComponent::Preview
    # @param label text
    # @param variant select [link, cta]
    # @param active toggle
    def playground(label: "Search", variant: :link, active: false)
      render_with_template(locals: { label:, variant:, active: })
    end

    def link
      render_with_template
    end

    def active
      render_with_template
    end

    # The filled call-to-action / current-section treatment.
    def cta
      render_with_template
    end
  end
end
