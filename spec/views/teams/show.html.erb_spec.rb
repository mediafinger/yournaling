RSpec.describe "teams/show", type: :view do
  before do
    assign(:team, Team.create!(
      name: "The Name"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/The Name/)
  end
end
