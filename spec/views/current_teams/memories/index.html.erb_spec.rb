RSpec.describe "current_teams/memories/index", type: :view do
  let(:memories) { FactoryBot.create_list(:memory, 2) }

  before do
    assign(:memories, memories)
  end

  it "renders a list of memories" do
    render

    assert_select "article", text: Regexp.new(memories.first.memo)

    assert_select "article", text: Regexp.new(memories.last.memo)
  end
end
