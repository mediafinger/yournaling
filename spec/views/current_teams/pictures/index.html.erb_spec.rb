RSpec.describe "current_teams/pictures/index", type: :view do
  before do
    assign(:pictures,
      [
        FactoryBot.create(:picture, name: "test-pic"),
        FactoryBot.create(:picture, name: "test-pic"),
      ]
    )
  end

  it "renders a list of pictures" do
    render

    assert_select "img", src: /macbookair_stickered.jpg/, count: 2
  end
end
