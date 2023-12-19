require "rails_helper"

RSpec.describe "locations/show", type: :view do
  let(:lat) { 41.3819253 }
  let(:long) { 2.1656894 }
  let(:team) { FactoryBot.create(:team) }

  before do
    assign(:location, Location.create!(
      name: "Flat in Carrer Ferlandina",
      url: "https://www.google.de/maps/place/#{lat},#{long}",
      lat: lat,
      long: long,
      address: {},
      team: team
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Flat in Carrer Ferlandina/)
    expect(rendered).to match(%r{https://www.google.de/maps/place/41.3819253,2.1656894})
    expect(rendered).to match(/#{lat}/)
    expect(rendered).to match(/#{long}/)
    expect(rendered).to match(/{}/)
  end
end
