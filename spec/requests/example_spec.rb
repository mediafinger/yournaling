# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/example", type: :request do
  describe "GET /example" do
    it "renders the showcase for a guest without authentication" do
      get "/example"

      expect(response).to have_http_status(:ok)
    end

    it "loads the standalone example stylesheet and Fraunces webfont" do
      get "/example"

      expect(response.body).to include("example")
      expect(response.body).to include("Fraunces")
      expect(response.body).to include('class="yui-body"')
    end

    it "shows the composed Memory and Chronicle record cards" do
      get "/example"

      expect(response.body).to include("yui-memory-card")
      expect(response.body).to include("yui-chronicle-card")
      expect(response.body).to include("A year on the coast")
    end

    it "renders the button, badge, field and icon components" do
      get "/example"

      aggregate_failures do
        expect(response.body).to include("yui-btn yui-btn--primary")
        expect(response.body).to include("yui-badge yui-badge--success")
        expect(response.body).to include("yui-field")
        expect(response.body).to include("yui-icon")
      end
    end
  end
end
