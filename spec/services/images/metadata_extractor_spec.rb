# frozen_string_literal: true

require "rails_helper"

RSpec.describe Images::MetadataExtractor, type: :service do
  describe ".call" do
    context "with a JPEG carrying full EXIF (GPS + timestamp + camera)" do
      subject(:metadata) { described_class.call(ImageFixtures::ORIGINAL.to_s) }

      it "reads the pixel geometry and classifies the orientation" do
        expect(metadata.width).to eq(1832)
        expect(metadata.height).to eq(1270)
        expect(metadata).to be_landscape
        expect(metadata.rotated).to be(false)
      end

      it "sniffs the content type from the bytes and records the byte size" do
        expect(metadata.content_type).to eq("image/jpeg")
        expect(metadata.byte_size).to eq(File.size(ImageFixtures::ORIGINAL))
      end

      it "reads the capture timestamp" do
        expect(metadata.taken_at).to eq(ImageFixtures::EXIF_TAKEN_AT)
      end

      it "reads the GPS fix" do
        expect(metadata.latitude).to be_within(0.0001).of(ImageFixtures::EXIF_LATITUDE)
        expect(metadata.longitude).to be_within(0.0001).of(ImageFixtures::EXIF_LONGITUDE)
        expect(metadata.altitude).to be_within(0.1).of(ImageFixtures::EXIF_ALTITUDE)
        expect(metadata).to be_gps
        expect(metadata.coordinates).to eq([metadata.latitude, metadata.longitude])
      end

      it "reads the camera make and model" do
        expect(metadata.camera_make).to eq("Google")
        expect(metadata.camera_model).to eq("Pixel 4a")
        expect(metadata.camera).to eq("Google Pixel 4a")
      end
    end

    context "with a genuine portrait image" do
      subject(:metadata) { described_class.call(ImageFixtures.path(:portrait_gps).to_s) }

      it "reports portrait orientation" do
        expect(metadata.width).to eq(1270)
        expect(metadata.height).to eq(1832)
        expect(metadata).to be_portrait
        expect(metadata.rotated).to be(false)
      end
    end

    context "with a square image" do
      subject(:metadata) { described_class.call(ImageFixtures.path(:square_gps).to_s) }

      it "reports square orientation" do
        expect(metadata.width).to eq(metadata.height)
        expect(metadata).to be_square
      end
    end

    context "with landscape pixels tagged EXIF Orientation=6" do
      subject(:metadata) { described_class.call(ImageFixtures.path(:exif_orientation_6).to_s) }

      it "returns the display dimensions (transposed) and flags rotation" do
        expect(metadata.width).to eq(1270)
        expect(metadata.height).to eq(1832)
        expect(metadata).to be_portrait
        expect(metadata.rotated).to be(true)
      end
    end

    context "with a JPEG whose metadata was stripped" do
      subject(:metadata) { described_class.call(ImageFixtures.path(:no_exif).to_s) }

      it "still reads geometry but no EXIF" do
        expect(metadata.width).to eq(1832)
        expect(metadata.orientation).to eq(:landscape)
        expect(metadata.taken_at).to be_nil
        expect(metadata.latitude).to be_nil
        expect(metadata).not_to be_gps
        expect(metadata.camera).to be_nil
      end
    end

    context "with a PNG (a format that never carries GPS EXIF)" do
      subject(:metadata) { described_class.call(ImageFixtures.path("plain.png").to_s) }

      it "reads geometry and content type, leaves EXIF fields nil" do
        expect(metadata.content_type).to eq("image/png")
        expect(metadata.width).to eq(800)
        expect(metadata.taken_at).to be_nil
        expect(metadata.latitude).to be_nil
      end
    end

    context "with an ActionDispatch uploaded file" do
      subject(:metadata) { described_class.call(ImageFixtures.upload(:original)) }

      it "resolves the tempfile path and extracts normally" do
        expect(metadata.width).to eq(1832)
        expect(metadata).to be_gps
      end
    end

    context "with a non-image file" do
      let(:tempfile) do
        Tempfile.new(["broken", ".jpg"]).tap { |f|
          f.write("not an image")
          f.rewind
        }
      end

      after { tempfile.close! }

      it "does not raise and returns an all-nil result" do
        metadata = described_class.call(tempfile.path)

        expect(metadata.width).to be_nil
        expect(metadata.orientation).to be_nil
        expect(metadata.latitude).to be_nil
      end
    end

    context "with a missing file" do
      it "does not raise" do
        expect { described_class.call("/no/such/file.jpg") }.not_to raise_error
      end
    end
  end
end
