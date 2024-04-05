require "rails_helper"

RSpec.describe "current_teams/memories/edit", type: :view do
  let(:user) { FactoryBot.create(:user) }
  let(:team) { FactoryBot.create(:team) }

  let(:memory) { Memory.create!(memo: "Memo Text", team: team) }

  before do
    allow(view).to receive(:current_team).and_return(team)
    assign(:memory, memory)
  end

  it "renders the edit memory form" do
    render

    assert_select "form[action=?][method=?]", current_team_memory_path(memory), "post" do
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
