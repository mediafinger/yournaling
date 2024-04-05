require "rails_helper"

RSpec.describe "current_teams/memories/new", type: :view do
  let(:user) { FactoryBot.create(:user) }
  let(:team) { FactoryBot.create(:team) }

  before do
    allow(view).to receive(:current_team).and_return(team)

    assign(:memory, Memory.new(memo: "Memo Text", team: team))
  end

  it "renders new memory form" do
    render

    assert_select "form[action=?][method=?]", current_team_memories_path, "post" do
      assert_select "textarea[name=?]", "memory[memo]"

      # TODO
      # assert_select "input[name=?]", "memory[name]"
      # assert_select "select[name=?]", "memory[country_code]"
      # assert_select "input[name=?]", "memory[address]"
      # assert_select "input[name=?]", "memory[lat]"
      # assert_select "input[name=?]", "memory[long]"
      # assert_select "input[name=?]", "memory[url]"
    end
  end
end
