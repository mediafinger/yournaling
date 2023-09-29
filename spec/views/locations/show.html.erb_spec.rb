require "rails_helper"

RSpec.describe "locations/show", type: :view do
  let(:location) { FactoryBot.create(:location, name: "Remote spot", country_code: "de") }

  before do
    assign(:location, location)
  end

  it "renders attributes in <p>" do
    render

    expect(rendered).to match(/#{location.name}/)
    expect(rendered).to match(/#{location.address}/)
    expect(rendered).to match(/Germany/)
    # expect(rendered).to match(/#{location.link}/) # TODO: match link
    # expect(rendered).to match(/#{location.lat}/) # TODO
    # expect(rendered).to match(/#{location.long}/) # TODO
  end
end
