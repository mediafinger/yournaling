require "rails_helper"

RSpec.describe "locations/show", type: :view do
  before do
    assign(:location, Location.create!(
      name: "Name",
      url: "MyText",
      lat: "9.99",
      long: "9.99",
      address: "",
      team: nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
  end
end
