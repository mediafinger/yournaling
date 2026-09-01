# frozen_string_literal: true

module Yui
  # @label Tabs
  class TabsComponentPreview < ViewComponent::Preview
    # @param active number
    def playground(active: 0)
      render_with_template(locals: { active: })
    end

    def default
      render_with_template
    end
  end
end
