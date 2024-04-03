require "rails_helper"

RSpec.describe "current_teams/locations/show", type: :view do
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
    expect(rendered).to match(/Flat in Carrer Ferlandina/)
    expect(rendered).to match(/Spain/)
    expect(rendered).to match(/{}/)
    expect(rendered).to match(/#{lat}/)
    expect(rendered).to match(/#{long}/)
    expect(rendered).to match(%r{https://www.google.com/maps/place/41.3819253,2.1656894})
  end
end
