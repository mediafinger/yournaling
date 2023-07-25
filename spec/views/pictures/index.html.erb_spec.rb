require 'rails_helper'

RSpec.describe "pictures/index", type: :view do
  before(:each) do
    assign(:pictures,
      [
        FactoryBot.create(:picture, :with_image, name: "test-pic"),
        FactoryBot.create(:picture, :with_image, name: "test-pic"),
      ]
    )
  end

  pending "renders a list of pictures" do
    render

    assert_select "img", src: /macbookair_stickered.jpg/, count: 2
  end
end
