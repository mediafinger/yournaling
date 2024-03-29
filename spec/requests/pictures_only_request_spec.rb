# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to test the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator. If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails. There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.

RSpec.describe "/pictures_only", type: :request do
  let(:file_content_type) { "image/jpeg" }
  let(:file_path) { "spec/support/macbookair_stickered.jpg" }
  let(:file) { Rack::Test::UploadedFile.new(file_path, file_content_type) }
  let(:name) { "#{Faker::Address.community}, #{Faker::Address.city}" }
  let(:date) { Time.zone.today.iso8601 }
  let(:team) { FactoryBot.create(:team) }
  let(:user) { FactoryBot.create(:user) }
  let(:roles) { %i[owner manager editor] }
  let(:valid_attributes) { { file: file, date: Time.zone.today, name: name, team: team } }
  let(:invalid_attributes) { { file: nil, date: Time.zone.today, name: nil, team: team } }

  before { Member.create!(team: team, user: user, roles: Array(roles.sample)) }

  describe "GET /show" do
    it "renders a successful response" do
      picture = Picture.create! valid_attributes

      get picture_url(picture.urlsafe_id)

      expect(response).to be_successful
    end
  end
end
