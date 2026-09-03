# frozen_string_literal: true

require "rails_helper"
require "ruby-vips"

RSpec.describe ImageUploadConversionService, type: :service do
  let(:jpeg_path) { "spec/support/macbookair_stickered.jpg" }
  let(:jpeg_upload) { Rack::Test::UploadedFile.new(jpeg_path, "image/jpeg") }

  describe ".call" do
    context "with a valid JPEG file" do
      it "converts the image to webp and stores it as an ActiveStorage blob" do
        blob = described_class.call(file: jpeg_upload, name: "macbook air photo")

        expect(blob).to be_an_instance_of(ActiveStorage::Blob)
        expect(blob.content_type).to eq("image/webp")
        expect(blob.filename.to_s).to eq("macbook_air_photo.webp")
        expect(blob.byte_size).to be >= Picture::MIN_BYTE_SIZE
        expect(blob.byte_size).to be <= Picture::MAX_BYTE_SIZE
      end

      it "parameterizes the name with underscores in the filename" do
        blob = described_class.call(file: jpeg_upload, name: "Sunset at Sierra Nevada (Spain) #2026!")

        expect(blob.filename.to_s).to eq("sunset_at_sierra_nevada_spain_2026.webp")
      end
    end

    context "with a valid PNG file" do
      let(:png_tempfile) { Tempfile.new(["sample", ".png"]) }
      let(:png_upload) do
        Vips::Image.black(800, 600).write_to_file(png_tempfile.path)
        Rack::Test::UploadedFile.new(png_tempfile.path, "image/png")
      end

      after do
        png_tempfile.close
        png_tempfile.unlink
      end

      it "converts the PNG image to webp" do
        blob = described_class.call(file: png_upload, name: "png sample")

        expect(blob.content_type).to eq("image/webp")
        expect(blob.filename.to_s).to eq("png_sample.webp")
      end
    end

    context "with an oversized image exceeding MAX_PIXEL dimensions" do
      let(:oversized_tempfile) { Tempfile.new(["oversized", ".jpg"]) }
      let(:oversized_upload) do
        Vips::Image.black(4500, 3500).write_to_file(oversized_tempfile.path)
        Rack::Test::UploadedFile.new(oversized_tempfile.path, "image/jpeg")
      end

      after do
        oversized_tempfile.close
        oversized_tempfile.unlink
      end

      it "downsizes dimensions to fit within MAX_PIXEL_WIDTH and MAX_PIXEL_HEIGHT" do
        blob = described_class.call(file: oversized_upload, name: "oversized photo")

        vips_image = Vips::Image.new_from_buffer(blob.download, "")
        expect(vips_image.width).to be <= Picture::MAX_PIXEL_WIDTH
        expect(vips_image.height).to be <= Picture::MAX_PIXEL_HEIGHT
      end
    end

    context "with a JPEG that carries EXIF / GPS metadata" do
      let(:exif_upload) { Rack::Test::UploadedFile.new(ImageFixtures::ORIGINAL, "image/jpeg") }

      it "strips all EXIF, GPS and ICC metadata from the stored file" do
        blob = described_class.call(file: exif_upload, name: "stripped")

        image = Vips::Image.new_from_buffer(blob.download, "")
        leaked = image.get_fields.grep(/exif|gps|orientation|icc|xmp/i)
        expect(leaked).to be_empty
      end
    end

    context "with a JPEG rotated only via its EXIF Orientation tag" do
      let(:rotated_upload) do
        Rack::Test::UploadedFile.new(ImageFixtures.path(:exif_orientation_6), "image/jpeg")
      end

      it "bakes the rotation into the pixels (portrait output, no orientation tag)" do
        blob = described_class.call(file: rotated_upload, name: "rotated")

        image = Vips::Image.new_from_buffer(blob.download, "")
        expect(image.height).to be > image.width
        expect { image.get("orientation") }.to raise_error(Vips::Error)
      end
    end

    context "with an image below the minimum pixel size" do
      let(:tiny_upload) { Rack::Test::UploadedFile.new(ImageFixtures.path(:tiny), "image/jpeg") }

      it "raises ImageTooSmall and does not create a blob" do
        expect {
          expect { described_class.call(file: tiny_upload, name: "tiny") }
            .to raise_error(ImageUploadConversionService::ImageTooSmall, /minimum/)
        }.not_to(change { ActiveStorage::Blob.count })
      end
    end

    context "with a corrupted non-image file" do
      let(:corrupt_tempfile) do
        Tempfile.new(["corrupt", ".jpg"]).tap do |file|
          file.write("NOT_A_VALID_IMAGE_DATA_HEADER_CORRUPTED")
          file.rewind
        end
      end
      let(:corrupt_upload) { Rack::Test::UploadedFile.new(corrupt_tempfile.path, "image/jpeg") }

      after do
        corrupt_tempfile.close
        corrupt_tempfile.unlink
      end

      it "raises an error during processing" do
        expect {
          described_class.call(file: corrupt_upload, name: "corrupt file")
        }.to raise_error(Vips::Error)
      end
    end
  end
end
