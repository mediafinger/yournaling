require 'rails_helper'

RSpec.describe "pictures/edit", type: :view do
  let(:picture) {
    Picture.create!(
      name: "MyString"
    )
  }

  before(:each) do
    assign(:picture, picture)
  end

  it "renders the edit picture form" do
    render

    assert_select "form[action=?][method=?]", picture_path(picture), "post" do

      assert_select "input[name=?]", "picture[name]"
    end
  end
end
