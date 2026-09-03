# frozen_string_literal: true

require "rails_helper"

RSpec.describe Picture, type: :model do
  subject(:picture) do
    described_class.new(file: blob_with_converted_image, name: "  Macbook Photo  ", team: team, visibility: "draft")
  end

  let(:original_content_type) { "image/jpeg" }
  let(:original_file_path) { "spec/support/macbookair_stickered.jpg" }
  let(:original_file) { Rack::Test::UploadedFile.new(original_file_path, original_content_type) }
  let(:blob_with_converted_image) { ImageUploadConversionService.call(file: original_file, name: "macbook_photo") }
  let(:team) { FactoryBot.create(:team) }

  describe "associations" do
    it "has many distinct chronicles through chronicle_entries" do
      picture.save!
      chronicle1 = FactoryBot.create(:chronicle, team: team)
      chronicle2 = FactoryBot.create(:chronicle, team: team)

      FactoryBot.create(:chronicle_entry, chronicle: chronicle1, team: team, entry: picture, position: 1)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle1, team: team, entry: picture, position: 2)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle2, team: team, entry: picture, position: 1)

      expect(picture.chronicles).to contain_exactly(chronicle1, chronicle2)
    end

    it "destroys associated chronicle_entries when picture is destroyed" do
      picture.save!
      chronicle = FactoryBot.create(:chronicle, team: team)
      entry = FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: picture)

      expect { picture.destroy! }.to change { ChronicleEntry.count }.by(-1)
      expect { entry.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "validations and normalizations" do
    it "is valid with a converted webp image blob" do
      expect(picture).to be_valid
      expect(picture.content_type).to eq("image/webp")
      expect(picture.bytes).to be >= Picture::MIN_BYTE_SIZE
      expect(picture.bytes).to be <= Picture::MAX_BYTE_SIZE
    end

    it "strips whitespace from name" do
      picture.save!
      expect(picture.name).to eq("Macbook Photo")
    end

    it "validates visibility inclusion" do
      picture.visibility = "unauthorized_status"
      expect(picture).not_to be_valid
      expect(picture.errors[:visibility]).to be_present
    end

    it "reports the actual byte size in the file-size error (not a hardcoded 0)" do
      undersized = described_class.new(team: team, visibility: "draft")
      undersized.file = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("x" * 42), filename: "small.webp", content_type: "image/webp"
      )

      undersized.valid?

      expect(undersized.errors[:file].join).to include("current size is 42 Bytes")
    end
  end

  describe "helper methods" do
    before { picture.save! }

    it "calculates size in bytes, kilobytes, and megabytes" do
      expect(picture.bytes).to eq(picture.file.blob.byte_size)
      expect(picture.kilobytes).to eq(picture.bytes / 1024)
      expect(picture.megabytes).to eq((picture.bytes / 1024.0 / 1024).round(2))
    end

    it "returns filename, content_type, and uploaded_at timestamp" do
      expect(picture.filename).to eq("macbook_photo.webp")
      expect(picture.content_type).to eq("image/webp")
      expect(picture.uploaded_at).to be_present
    end
  end

  describe "variant generation" do
    before { picture.save! }

    it "creates a thumbnail variant with max dimensions 160x120" do
      variant = picture.thumbnail
      expect(variant).to be_present
      expect(variant.variation.transformations[:resize_to_limit]).to eq([160, 120])
      expect(variant.variation.transformations[:format]).to eq(:webp)
    end

    it "creates a preview variant with max dimensions 400x300 and quality 85" do
      variant = picture.preview
      expect(variant).to be_present
      expect(variant.variation.transformations[:resize_to_limit]).to eq([400, 300])
      expect(variant.variation.transformations[:saver][:quality]).to eq(85)
    end

    it "creates a large variant with max dimensions 1200x900 and quality 90" do
      variant = picture.large
      expect(variant).to be_present
      expect(variant.variation.transformations[:resize_to_limit]).to eq([1200, 900])
      expect(variant.variation.transformations[:saver][:quality]).to eq(90)
    end

    it "supports custom variant generation via create_variant" do
      variant = picture.create_variant(max_width: 800, max_height: 600, quality: 75)
      expect(variant).to be_present
      expect(variant.variation.transformations[:resize_to_limit]).to eq([800, 600])
      expect(variant.variation.transformations[:saver][:quality]).to eq(75)
    end
  end

  describe "search index" do
    let(:saved_picture) { FactoryBot.create(:picture, team: team, name: "Mountain Summit View") }

    it "creates a PgSearch::Document when saved" do
      expect(PgSearch::Document.where(searchable_type: "Picture", searchable_id: saved_picture.id)).to exist
    end

    it "indexes the name in the document content" do
      expect(saved_picture.pg_search_document.content).to include(saved_picture.name)
    end

    it "sets team_id on the document" do
      expect(saved_picture.pg_search_document.team_id).to eq(team.id)
    end

    it "returns the record via the searchable association" do
      expect(saved_picture.pg_search_document.searchable).to eq(saved_picture)
    end
  end

  describe "#assign_uploaded_file" do
    subject(:picture) { described_class.new(team: team, visibility: "draft") }

    it "attaches a stripped webp and returns the extracted metadata", aggregate_failures: true do
      metadata = picture.assign_uploaded_file(
        ImageFixtures.upload(:original), name: "Cologne rooftop"
      )
      picture.save!

      expect(picture.content_type).to eq("image/webp")
      expect(picture.exif_stripped).to be(true)
      expect(metadata).to be_a(Images::Metadata)
    end

    it "records EXIF geometry, GPS, timestamp and camera on dedicated columns", aggregate_failures: true do
      picture.assign_uploaded_file(ImageFixtures.upload(:original), name: "Cologne rooftop")
      picture.save!

      expect(picture.image_width).to eq(1832)
      expect(picture.image_height).to eq(1270)
      expect(picture.original_content_type).to eq("image/jpeg")
      expect(picture.original_byte_size).to eq(File.size(ImageFixtures::ORIGINAL))
      expect(picture.camera_make).to eq("Google")
      expect(picture.camera_model).to eq("Pixel 4a")
      expect(picture.latitude).to be_within(0.0001).of(ImageFixtures::EXIF_LATITUDE)
      expect(picture.longitude).to be_within(0.0001).of(ImageFixtures::EXIF_LONGITUDE)
      expect(picture.taken_at).to eq(ImageFixtures::EXIF_TAKEN_AT)
    end

    it "defaults the date to the EXIF capture day when none is given" do
      picture.assign_uploaded_file(ImageFixtures.upload(:original), name: "x")

      expect(picture.date).to eq(Date.new(2022, 4, 12))
    end

    it "keeps an explicitly supplied date" do
      picture.assign_uploaded_file(ImageFixtures.upload(:original), name: "x", date: "2024-01-02")

      expect(picture.date).to eq(Date.new(2024, 1, 2))
    end

    it "leaves EXIF columns nil for a scrubbed upload" do
      picture.assign_uploaded_file(ImageFixtures.upload(:no_exif), name: "anon")
      picture.save!

      expect(picture.latitude).to be_nil
      expect(picture.taken_at).to be_nil
      expect(picture.date).to be_nil
      expect(picture).not_to be_geotagged
    end

    it "raises ImageTooSmall for an undersized image" do
      expect {
        picture.assign_uploaded_file(ImageFixtures.upload(:tiny), name: "tiny")
      }.to raise_error(ImageUploadConversionService::ImageTooSmall)
    end
  end

  describe "orientation and geometry helpers" do
    it "classifies a landscape upload" do
      picture = described_class.new(team: team, visibility: "draft")
      picture.assign_uploaded_file(ImageFixtures.upload(:original), name: "l")
      picture.save!

      expect(picture).to be_landscape
      expect(picture.orientation).to eq(:landscape)
      expect(picture.aspect_ratio).to eq((1832 / 1270.0).round(4))
    end

    it "classifies a portrait upload" do
      picture = described_class.new(team: team, visibility: "draft")
      picture.assign_uploaded_file(ImageFixtures.upload(:portrait_gps), name: "p")
      picture.save!

      expect(picture).to be_portrait
    end

    it "classifies a square upload" do
      picture = described_class.new(team: team, visibility: "draft")
      picture.assign_uploaded_file(ImageFixtures.upload(:square_gps), name: "s")
      picture.save!

      expect(picture).to be_square
      expect(picture.aspect_ratio).to eq(1.0)
    end

    it "falls back to the analyzed blob metadata when the columns are blank" do
      picture.save!
      picture.file.blob.analyze
      picture.update_columns(image_width: nil, image_height: nil)

      expect(picture.reload.dimensions).to eq([picture.file.blob.metadata[:width],
                                               picture.file.blob.metadata[:height]])
      expect(picture.orientation).to be_in(%i[landscape portrait square])
    end
  end

  describe "GPS helpers" do
    before do
      picture.assign_attributes(latitude: 50.9337, longitude: 6.9408)
    end

    it "exposes coordinates when geotagged" do
      expect(picture).to be_geotagged
      expect(picture.coordinates).to eq([50.9337, 6.9408])
      expect(picture.location_attributes_from_exif).to eq(lat: 50.9337, long: 6.9408)
    end

    it "validates the coordinate ranges" do
      picture.latitude = 120
      expect(picture).not_to be_valid
      expect(picture.errors[:latitude]).to be_present
    end

    it "has no coordinates without a fix" do
      picture.assign_attributes(latitude: nil, longitude: nil)
      expect(picture).not_to be_geotagged
      expect(picture.coordinates).to be_nil
      expect(picture.location_attributes_from_exif).to eq({})
    end
  end

  describe "#original_size" do
    it "humanises the pre-conversion byte size" do
      picture.original_byte_size = 2_500_000
      expect(picture.original_size).to eq("2.38 MB")
    end

    it "is nil when unknown" do
      expect(picture.original_size).to be_nil
    end
  end

  describe "parent visibility constraints" do
    it "prohibits reducing visibility when picture belongs to a published chronicle" do
      picture.visibility = "published"
      picture.save!

      chronicle = FactoryBot.create(:chronicle, team: team, name: "Summer Voyage", visibility: "published")
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: picture)

      picture.visibility = "internal"
      expect(picture).not_to be_valid
      expect(picture.errors[:visibility]).to be_present
      expect(picture.errors[:visibility].first).to include("cannot be limited to 'internal'")
      expect(picture.errors[:visibility].first).to include("Summer Voyage")
    end

    it "prohibits reducing visibility when picture belongs to a published memory" do
      picture.visibility = "published"
      picture.save!

      FactoryBot.create(:memory, team: team, memo: "Remembering sunny days", picture: picture,
        visibility: "published")

      picture.visibility = "internal"
      expect(picture).not_to be_valid
      expect(picture.errors[:visibility]).to be_present
      expect(picture.errors[:visibility].first).to include("cannot be limited to 'internal'")
      expect(picture.errors[:visibility].first).to include("Remembering sunny days")
    end

    it "allows reducing visibility when parent chronicle is also internal or less permissive" do
      picture.visibility = "published"
      picture.save!

      chronicle = FactoryBot.create(:chronicle, team: team, name: "Internal Draft", visibility: "internal")
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: picture)

      picture.visibility = "internal"
      expect(picture).to be_valid
    end
  end
end
