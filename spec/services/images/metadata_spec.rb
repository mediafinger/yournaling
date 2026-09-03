# frozen_string_literal: true

require "rails_helper"

RSpec.describe Images::Metadata do
  def build(**overrides)
    defaults = {
      width: 1832, height: 1270, orientation: :landscape, rotated: false,
      content_type: "image/jpeg", byte_size: 631_800,
      taken_at: Time.utc(2022, 4, 12, 18, 18, 12),
      latitude: 50.9337, longitude: 6.9408, altitude: 97.8,
      camera_make: "Google", camera_model: "Pixel 4a"
    }
    described_class.new(**defaults, **overrides)
  end

  describe "orientation predicates" do
    it { expect(build(orientation: :landscape)).to be_landscape }
    it { expect(build(orientation: :portrait)).to be_portrait }
    it { expect(build(orientation: :square)).to be_square }
  end

  describe "#gps? / #coordinates" do
    it "is true only when both axes are present" do
      expect(build).to be_gps
      expect(build(latitude: nil)).not_to be_gps
      expect(build(longitude: nil)).not_to be_gps
    end

    it "returns nil coordinates without a fix" do
      expect(build(latitude: nil).coordinates).to be_nil
    end
  end

  describe "#camera" do
    it "joins make and model" do
      expect(build.camera).to eq("Google Pixel 4a")
    end

    it "is nil when neither is known" do
      expect(build(camera_make: nil, camera_model: nil).camera).to be_nil
    end
  end

  describe "#to_location_attributes" do
    it "maps GPS onto Location's lat/long" do
      expect(build.to_location_attributes).to eq(lat: 50.9337, long: 6.9408)
    end

    it "is empty without a fix" do
      expect(build(latitude: nil).to_location_attributes).to eq({})
    end
  end

  describe "#to_picture_attributes" do
    it "maps geometry and EXIF onto Picture columns" do
      expect(build.to_picture_attributes).to include(
        taken_at: Time.utc(2022, 4, 12, 18, 18, 12),
        latitude: 50.9337, longitude: 6.9408, altitude: 97.8,
        camera_make: "Google", camera_model: "Pixel 4a",
        image_width: 1832, image_height: 1270,
        original_byte_size: 631_800, original_content_type: "image/jpeg"
      )
    end
  end
end
