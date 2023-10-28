RSpec.describe "pictures/index", type: :view do
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

    assert_select "img", src: /macbookair_stickered.jpg/, count: 4 # currently we show each image in 2 sizes
  end
end
