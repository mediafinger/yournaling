RSpec.describe "pictures/new", type: :view do
  before do
    assign(:picture, Picture.new(
      name: "MyString"
    ))
  end

  it "renders new picture form" do
    render

    assert_select "form[action=?][method=?]", pictures_path, "post" do
      assert_select "input[name=?]", "picture[name]"
    end
  end
end
