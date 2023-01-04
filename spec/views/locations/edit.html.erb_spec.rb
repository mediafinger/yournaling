require 'rails_helper'

RSpec.describe "locations/edit", type: :view do
  let(:location) {
    Location.create!(
      address: "MyText",
      lat: "9.99",
      long: "9.99",
      name: "MyString",
      link: "MyText"
    )
  }

  before(:each) do
    assign(:location, location)
  end

  it "renders the edit location form" do
    render

    assert_select "form[action=?][method=?]", location_path(location), "post" do

      assert_select "textarea[name=?]", "location[address]"

      assert_select "input[name=?]", "location[lat]"

      assert_select "input[name=?]", "location[long]"

      assert_select "input[name=?]", "location[name]"

      assert_select "textarea[name=?]", "location[link]"
    end
  end
end
