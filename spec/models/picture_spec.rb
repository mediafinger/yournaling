RSpec.describe Picture, type: :model do
  subject(:picture) do
    described_class.new(file: blob_with_converted_image, name: new_name, team: team, creator: user)
  end

  let(:original_content_type) { "image/jpeg" }
  let(:original_file_path) { "spec/support/macbookair_stickered.jpg" }
  let(:original_file) { Rack::Test::UploadedFile.new(original_file_path, original_content_type) }
  let(:new_name) { "new_picture" }
  let(:new_content_type) { "image/webp" }
  let(:blob_with_converted_image) { ImageUploadConversionService.call(file: original_file, name: new_name) }
  let(:team) { FactoryBot.create(:team) }
  let(:user) { FactoryBot.create(:user) }

  describe "#create" do
    it "attaches an image" do
      expect(picture).to be_valid
      expect(picture.content_type).to eq(new_content_type)
      expect(picture.bytes).to be >= Picture::MIN_BYTE_SIZE
      expect(picture.bytes).to be <= Picture::MAX_BYTE_SIZE
    end
  end

  describe "#update" do
    it "attaches an image" do
      picture.save!
      picture.reload.update!(name: "Updated Name", updater: user)

      expect(picture).to be_valid
      expect(picture.content_type).to eq(new_content_type)
      expect(picture.bytes).to be >= Picture::MIN_BYTE_SIZE
      expect(picture.bytes).to be <= Picture::MAX_BYTE_SIZE
      expect(picture.name).to eq("Updated Name")
    end
  end
end
