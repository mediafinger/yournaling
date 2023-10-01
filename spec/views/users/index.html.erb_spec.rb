RSpec.describe "users/index", type: :view do
  let(:users) { FactoryBot.create_list(:user, 2) }

  before do
    assign(:users, users)
  end

  it "renders a list of users" do
    render
    cell_selector = Rails::VERSION::STRING >= "7" ? "article>p" : "tr>td"
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Email".to_s), count: 2
  end
end
