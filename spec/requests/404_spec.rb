require "rails_helper"

RSpec.describe "404 request spec", type: :request do
  describe "GET /unknown" do
    it "returns an error" do
      expect(Rails.logger).to receive(:warn).with(
        /ActionController::RoutingError message='Path \/unknown could not be found' code=not_found status=404 id=/
      )

      get "/unknown"

      expect(response).to have_http_status(404)
      expect(parsed_response["error"]).to include(
        {
          "code" => "not_found",
          "id" => matches_uuid,
          "message" => "ActionController::RoutingError: Path /unknown could not be found",
        }
      )
    end
  end
end
