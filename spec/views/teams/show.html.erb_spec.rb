# frozen_string_literal: true

RSpec.describe "teams/show", type: :view do
  before do
    assign(:team, Team.create!(
      name: "The Name"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to include("The Name")
  end
end
