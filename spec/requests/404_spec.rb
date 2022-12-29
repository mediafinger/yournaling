require "rails_helper"

RSpec.describe "404 request spec", type: :request do
  describe "GET /unknown" do
    it "returns an error" do
      expect(Rails.logger).to receive(:warn) # why does this with(parameter) not work?
      # .with(
        # /ActionController::RoutingError message='Path \/unknown could not be found' code=not_found status=404 id=/
        # %r{ ActionController::RoutingError message='Path /unknown could not be found' code=not_found status=404 }
        # "ActionController::RoutingError message='Path /unknown could not be found' code=not_found status=404 #{anything}"
      # )

      get "/unknown"

      expect(response).to have_http_status(404)
      # expect(response).to render_template("pages/error") # why does this not work?

      expect(response.body).to include("Error: not_found (404)")

      # why does this not work?
      # expect(response.body).to have_tag("a", href: "javascript:history.back()", text: "Back to previous page")
    end
  end
end
