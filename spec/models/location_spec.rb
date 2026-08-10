# frozen_string_literal: true

require "rails_helper"

RSpec.describe Location, type: :model do
  subject(:location) { described_class.new(valid_attributes) }

  let(:team) { FactoryBot.create(:team) }
  let(:valid_attributes) do
    {
      team: team,
      name: "Cabo de Gata Camping",
      country_code: "es",
      address: "Playa de los Genoveses, San Jose",
      lat: 36.7491,
      long: -2.2425,
      visibility: "internal",
    }
  end

  describe "validations and coordinate bounds" do
    it "is valid with valid attributes" do
      expect(location).to be_valid
    end

    it "validates latitude is within -90.0 and 90.0" do
      location.lat = 90.0001
      expect(location).not_to be_valid
      expect(location.errors[:lat]).to be_present

      location.lat = -90.0001
      expect(location).not_to be_valid

      location.lat = 45.0
      expect(location).to be_valid
    end

    it "validates longitude is within -180.0 and 180.0" do
      location.long = 180.0001
      expect(location).not_to be_valid
      expect(location.errors[:long]).to be_present

      location.long = -180.0001
      expect(location).not_to be_valid

      location.long = -3.7038
      expect(location).to be_valid
    end

    it "validates name uniqueness scoped to team" do
      location.save!
      duplicate = described_class.new(valid_attributes)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to be_present

      # Allowed for another team
      other_team = FactoryBot.create(:team)
      duplicate.team = other_team
      expect(duplicate).to be_valid
    end

    it "validates country_code against CountriesEnForSelectService" do
      location.country_code = "xx"
      expect(location).not_to be_valid
      expect(location.errors[:country_code]).to be_present
    end

    it "requires address, coordinates, or url to be given" do
      empty_loc = described_class.new(team: team, name: "Nowhere", country_code: "es", visibility: "internal")
      expect(empty_loc).not_to be_valid
      expect(empty_loc.errors[:base]).to include("Address, Coordinates, or URL must be provided")
    end
  end

  describe "attribute normalization" do
    it "normalizes country_code to stripped lowercase" do
      loc = described_class.create!(valid_attributes.merge(country_code: "  ES  "))
      expect(loc.country_code).to eq("es")
    end

    it "normalizes name by stripping whitespace" do
      loc = described_class.create!(valid_attributes.merge(name: "  Wild Camping Spot  "))
      expect(loc.name).to eq("Wild Camping Spot")
    end

    it "normalizes url with https scheme" do
      loc = described_class.create!(valid_attributes.merge(url: "example.com/campsite"))
      expect(loc.url).to eq("https://example.com/campsite")
    end
  end

  describe "helper methods" do
    it "returns coordinates array" do
      expect(location.coordinates).to eq([36.7491, -2.2425])
    end

    it "detects coordinate changes" do
      location.save!
      expect(location.coordinates_changed?).to be false
      location.lat = 40.4168
      expect(location.coordinates_changed?).to be true
    end

    it "generates Google Maps place URL" do
      expect(location.gmaps_coordinates_url).to eq("https://www.google.com/maps/place/36.7491,-2.2425")
    end

    it "generates Geoapify static map URL" do
      map_url = location.map(width: 600, height: 400)
      expect(map_url).to include("maps.geoapify.com/v1/staticmap")
      expect(map_url).to include("width=600")
      expect(map_url).to include("height=400")
      expect(map_url).to include("center=lonlat:-2.2425,36.7491")
    end
  end

  describe "callbacks" do
    it "creates a Google Maps URL if url is not provided" do
      loc = described_class.create!(valid_attributes.except(:url))
      expect(loc.url).to eq("https://www.google.com/maps/place/36.7491,-2.2425")
    end
  end
end
