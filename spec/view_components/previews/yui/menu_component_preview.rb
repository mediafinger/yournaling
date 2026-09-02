# frozen_string_literal: true

module Yui
  # @label Menu
  class MenuComponentPreview < ViewComponent::Preview
    # @param label text
    # @param align select [start, end]
    def playground(label: "+ New", align: :start)
      render_with_template(locals: { label:, align: })
    end

    def default
      render_with_template
    end
  end
end
