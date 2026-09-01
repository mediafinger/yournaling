# frozen_string_literal: true

# Renders the /example design-language showcase. It is intentionally standalone:
# its own layout (layouts/example) loads the design/ stylesheets (incl. showcase.css)
# and it does not depend on authentication or an existing team.
class ExampleController < ApplicationController
  skip_before_action :authenticate
  skip_verify_authorized

  layout "example"

  def show; end
end
