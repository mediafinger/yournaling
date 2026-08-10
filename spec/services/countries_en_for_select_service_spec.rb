# frozen_string_literal: true

require "rails_helper"

RSpec.describe CountriesEnForSelectService, type: :service do
  describe ".call" do
    it "returns a mapping of country codes to formatted display names with flags" do
      result = described_class.call

      expect(result).to be_a(Hash)
      expect(result["es"]).to include("Spain", "🇪🇸", "[ES]")
      expect(result["de"]).to include("Germany", "🇩🇪", "[DE]")
      expect(result["us"]).to include("United States", "🇺🇸", "[US]")
      expect(result["fr"]).to include("France", "🇫🇷", "[FR]")
    end
  end
end
