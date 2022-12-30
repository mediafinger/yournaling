require "rails_helper"

RSpec.describe "locations/index", type: :view do
  before do
    assign(:locations,
      [
        Location.create!(
          address: "an address",
          lat: "9.99",
          long: "9.99",
          name: "a Name",
          link: "http://example.com"
        ),
        Location.create!(
          address: "an address",
          lat: "9.99",
          long: "9.99",
          name: "a Name",
          link: "http://example.com"
        ),
      ]
    )
  end

  it "renders a list of locations" do
    render

    cell_selector = Rails::VERSION::STRING >= "7" ? "article>p" : "tr>td"
    assert_select cell_selector, text: Regexp.new("a Name"), count: 2
    assert_select cell_selector, text: Regexp.new("an address"), count: 2
    assert_select cell_selector, text: Regexp.new("Germany"), count: 2
    # assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    # assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    # assert_select cell_selector, text: Regexp.new("http://example.com"), count: 2
  end
end
