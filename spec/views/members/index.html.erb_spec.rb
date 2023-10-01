RSpec.describe "members/index", type: :view do
  let(:members) { FactoryBot.create_list(:member, 2) }

  before do
    assign(:members, members)
  end

  it "renders a list of members" do
    render
    cell_selector = Rails::VERSION::STRING >= "7" ? "article>p" : "tr>td"
    assert_select cell_selector, text: Regexp.new(User.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(Team.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Role"), count: 2
  end
end
