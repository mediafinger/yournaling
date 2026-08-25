# frozen_string_literal: true

RSpec.describe ErrorHandler do
  describe "MAP_RAILS_ERRORS" do
    # ErrorHandler installs a `rescue_from ::StandardError`, which runs *before* ActionDispatch's
    # own `rescue_responses` table. Any framework error missing from this map is therefore
    # downgraded to a 500, however well Rails classifies it by default.
    it "maps ActionController::TooManyRequests to 429, so `rate_limit` is not reported as a 500" do
      expect(described_class::MAP_RAILS_ERRORS).to include(
        "ActionController::TooManyRequests" => { code: :too_many_requests, status: 429 }
      )
    end
  end
end
