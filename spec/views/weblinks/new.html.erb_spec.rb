require "rails_helper"

RSpec.describe "weblinks/new", type: :view do
  let(:team) { FactoryBot.create(:team) }
  let(:weblink) { FactoryBot.build(:weblink, team: team) }

  before do
    allow(view).to receive(:current_team).and_return(team)
    assign(:weblink, weblink)
  end

  it "renders new weblink form" do
    render

    assert_select "form[action=?][method=?]", weblinks_path, "post" do
      assert_select "input[name=?]", "weblink[name]"

      assert_select "input[name=?]", "weblink[url]"

      assert_select "textarea[name=?]", "weblink[description]"
    end
  end
end
