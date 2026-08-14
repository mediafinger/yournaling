# frozen_string_literal: true

require "rails_helper"

RSpec.describe Picture, type: :model do
  subject(:picture) do
    described_class.new(file: blob_with_converted_image, name: "  Macbook Photo  ", team: team, visibility: "internal")
  end

  let(:original_content_type) { "image/jpeg" }
  let(:original_file_path) { "spec/support/macbookair_stickered.jpg" }
  let(:original_file) { Rack::Test::UploadedFile.new(original_file_path, original_content_type) }
  let(:blob_with_converted_image) { ImageUploadConversionService.call(file: original_file, name: "macbook_photo") }
  let(:team) { FactoryBot.create(:team) }

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
end
