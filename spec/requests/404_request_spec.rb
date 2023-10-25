RSpec.describe "404 request spec", type: :system do
  describe "GET /unknown" do
    it "returns an error page with back link" do
      expect(Rails.logger).to receive(:warn).with(
        /ActionController::RoutingError message='Path \/unknown could not be found' code=not_found status=404 id=/
      )

      visit "/unknown"

      expect(page).to have_current_path("/unknown", ignore_query: true)

      expect(page.status_code).to eq(404) # not supported by selenium driver
      # save_and_open_page # not supported by rack-test driver

      expect(page).to have_text("Error: not_found (404)")

      main = page.find("main")
      main.find_link("Back to previous page", href: "javascript:history.back()")
    end
  end
end
