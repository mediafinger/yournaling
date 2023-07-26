RSpec.describe ImageUploadConversionService, type: :service do
  let(:original_content_type) { "image/jpeg" }
  let(:original_file_path) { "spec/support/macbookair_stickered.jpg" }
  let(:original_file) { Rack::Test::UploadedFile.new(original_file_path, original_content_type) }
  let(:new_name) { "new_picture" }
  let(:new_content_type) { "image/webp" }

  context "when the file is valid" do
    it "converts the image" do
      blob_with_converted_file = described_class.call(file: original_file, name: new_name)

      expect(blob_with_converted_file.content_type).to eq(new_content_type)
      expect(blob_with_converted_file.filename.to_s).to eq("#{new_name}.webp") # service stores with suffix
      expect(blob_with_converted_file.byte_size).to be >= Picture::MIN_BYTE_SIZE
      expect(blob_with_converted_file.byte_size).to be <= Picture::MAX_BYTE_SIZE
    end
  end
end
