RSpec.describe "teams/index", type: :view do
  before do
    assign(:teams,
      [
        Team.create!(name: Faker::Name.name),
        Team.create!(name: Faker::Name.name),
      ])
  end

  it "renders a list of teams" do
    render
    cell_selector = Rails::VERSION::STRING >= "7" ? "article>p" : "tr>td"
    assert_select cell_selector, text: Regexp.new("Name"), count: 2
  end
end
