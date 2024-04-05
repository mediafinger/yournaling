require "rails_helper"

RSpec.describe "current_teams/memories/show", type: :view do
  let(:memory) { Memory.create!(memo: "Memo Text", team: team) }
  let(:lat) { 41.3819253 }
  let(:long) { 2.1656894 }
  let(:team) { FactoryBot.create(:team) }

  before do
    assign(:memory, memory.reload)
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Memo Text/)
  end
end
