RSpec.describe "current_teams/locations/index", type: :view do
  let(:locations) { FactoryBot.create_list(:location, 2) }

  before do
    assign(:locations, locations)
  end

  it "renders a list of locations" do
    render

    assert_select "article", text: Regexp.new(locations.first.name)
    assert_select "article", text: Regexp.new(locations.first.lat.to_s)
    assert_select "article", text: Regexp.new(locations.first.long.to_s)
    assert_select "article", text: Regexp.new(locations.first.address.to_s)

    assert_select "article", text: Regexp.new(locations.last.name)
    assert_select "article", text: Regexp.new(locations.last.lat.to_s)
    assert_select "article", text: Regexp.new(locations.last.long.to_s)
    assert_select "article", text: Regexp.new(locations.last.address.to_s)
  end
end
