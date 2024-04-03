require "rails_helper"

RSpec.describe "teams/locations/show", type: :view do
  let(:location) do
    Location.create!(
      name: "Flat in Carrer Ferlandina",
      country_code: "es",
      address: {},
      lat: lat,
      long: long,
      team: team
    )
  end
  let(:lat) { 41.3819253 }
  let(:long) { 2.1656894 }
  let(:team) { FactoryBot.create(:team) }

  before do
    assign(:location, location.reload)
  end

  it "renders attributes in <p>" do
    render

    expect(rendered).to include("Flat in Carrer Ferlandina")
    expect(rendered).to include("Spain (ES)")
    # expect(rendered).to include(lat.to_s)
    # expect(rendered).to include(long.to_s)
    # expect(rendered).to match(%r{https://www.google.com/maps/place/41.3819253,2.1656894})
  end
end
