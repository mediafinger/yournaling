require "rails_helper"

RSpec.describe "locations/edit", type: :view do
  let(:location) do
    Location.create!(
      address: "MyText",
      country: "de",
      lat: "9.99",
      long: "9.99",
      name: "MyString",
      link: "http://example.com/nice_place"
    )
  end

  before do
    assign(:location, location)
  end

  it "renders the edit location form" do
    render

    assert_select "form[action=?][method=?]", location_path(location), "post" do
      assert_select "input[name=?]", "location[address]"
      assert_select "select[name=?]", "location[country]"
      assert_select "input[name=?]", "location[lat]"
      assert_select "input[name=?]", "location[long]"
      assert_select "input[name=?]", "location[name]"
      assert_select "input[name=?]", "location[link]"
    end
  end
end
