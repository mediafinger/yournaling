RSpec.describe "/admin/jobs", type: :system do
  let(:user) { FactoryBot.create(:user, role: role) }

  describe "GET /admin/jobs" do
    context "user is signed in" do
      before { visit_sign_in(user) }

      context "user is admin" do
        let(:role) { "admin" }

        it "renders a successful response", aggregate_failures: true do
          visit "/admin/jobs"

          expect(page).to have_current_path("/admin/jobs", ignore_query: true)
          expect(page.status_code).to eq(200) # not supported by selenium driver
        end
      end

      context "user is not an admin" do
        let(:role) { "user" }

        it "renders a not found response", aggregate_failures: true do
          visit "/admin/jobs"

          expect(page).to have_current_path("/admin/jobs", ignore_query: true)
          expect(page.status_code).to eq(404) # not supported by selenium driver
        end
      end
    end

    context "user is not signed in" do
      let(:role) { "admin" }

      it "renders a not found response", aggregate_failures: true do
        visit "/admin/jobs"

        expect(page).to have_current_path("/admin/jobs", ignore_query: true)
        expect(page.status_code).to eq(404) # not supported by selenium driver
      end
    end
  end
end
