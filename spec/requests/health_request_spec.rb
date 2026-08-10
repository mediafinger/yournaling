# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Health Check Endpoint (/up)", type: :request do
  describe "GET /up" do
    context "when database is operational" do
      before do
        FactoryBot.create(:user)
      end

      it "returns HTTP 200 with green status HTML" do
        get "/up"

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("background-color: green")
        expect(response.body).to include("200")
      end
    end

    context "when database query fails" do
      before do
        allow(User).to receive(:first!).and_raise(ActiveRecord::ConnectionNotEstablished)
      end

      it "returns HTTP 503 with red status HTML" do
        get "/up"

        expect(response).to have_http_status(:service_unavailable)
        expect(response.body).to include("background-color: red")
        expect(response.body).to include("503")
      end
    end
  end
end
