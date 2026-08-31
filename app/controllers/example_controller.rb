# frozen_string_literal: true

# Renders the /example design-language showcase. It is intentionally standalone:
# it uses its own layout (layouts/example) and the example.css stylesheet, and
# does not depend on authentication or an existing team.
class ExampleController < ApplicationController
  skip_before_action :authenticate
  skip_verify_authorized

  layout "example"

  def show; end
end
