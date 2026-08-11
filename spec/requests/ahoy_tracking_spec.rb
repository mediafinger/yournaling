# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Ahoy Visit and Event Tracking", type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:browser_headers) do
    {
      "HTTP_USER_AGENT" =>
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " \
        "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    }
  end

  describe "visit tracking" do
    context "when request is made by an unauthenticated guest" do
      it "tracks anonymous guest visits and creates an Ahoy::Visit with nil user" do
        expect {
          get "/", headers: browser_headers
        }.to change { Ahoy::Visit.count }.by(1)

        visit = Ahoy::Visit.last
        expect(visit.user_id).to be_nil
        expect(visit.browser).to eq("Chrome")
        expect(visit.os).to eq("Mac")
        expect(visit.visitor_token).to be_present
      end
    end

    context "when user is signed in" do
      it "creates an Ahoy::Visit associated with the authenticated user" do
        expect {
          post login_path, params: { email: user.email, password: "foobar1234" }, headers: browser_headers
          get "/", headers: browser_headers
        }.to change { Ahoy::Visit.count }.by_at_least(1)

        visit = Ahoy::Visit.last
        expect(visit.user_id).to eq(user.id)
        expect(visit.browser).to eq("Chrome")
        expect(visit.os).to eq("Mac")
      end
    end

    context "when guest subsequently signs in" do
      it "associates the guest visit with the newly signed in user via ahoy.authenticate" do
        # Guest visit
        get "/", headers: browser_headers
        guest_visit = Ahoy::Visit.last
        expect(guest_visit.user_id).to be_nil

        # Sign in in same session
        post login_path, params: { email: user.email, password: "foobar1234" }, headers: browser_headers

        expect(guest_visit.reload.user_id).to eq(user.id)
      end
    end
  end

  describe "event tracking" do
    it "persists tracked events into record_events" do
      get "/", headers: browser_headers

      visit = Ahoy::Visit.last
      expect(visit).to be_present

      expect {
        RecordEventService.call(
          record: user,
          team: nil,
          user: user,
          name: "homepage_viewed",
          properties: { page: "home" }
        )
      }.to change { RecordEvent.count }.by(1)

      event = RecordEvent.last
      expect(event.name).to eq("homepage_viewed")
      expect(event.user_id).to eq(user.id)
      expect(event.properties).to eq("page" => "home")
    end
  end
end
