# frozen_string_literal: true

module Yui
  # @label Navbar
  class NavbarComponentPreview < ViewComponent::Preview
    # @param area select [public, team, admin]
    def playground(area: "public")
      render_with_template(locals: { area: })
    end

    def default
      render_with_template
    end
  end
end
