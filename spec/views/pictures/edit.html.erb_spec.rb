RSpec.describe "pictures/edit", type: :view do
  let(:picture) { FactoryBot.create(:picture) }

  before do
    assign(:picture, picture)
  end

  it "renders the edit picture form" do
    render

    assert_select "form[action=?][method=?]", picture_path(picture), "post" do
      assert_select "input[name=?]", "picture[name]"
    end
  end
end
