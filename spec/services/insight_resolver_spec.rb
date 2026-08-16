# frozen_string_literal: true

require "rails_helper"

RSpec.describe InsightResolver do
  let(:team) { FactoryBot.create(:team) }
  let(:user) { FactoryBot.create(:user) }
  let(:parent) { FactoryBot.create(:chronicle, team: team, start_date: Date.current, visibility: "published") }
  let(:resolver) do
    described_class.new(
      parent: parent,
      team: team,
      date: Date.current,
      visibility: "published",
      user: user
    )
  end

  let(:uploaded_file) do
    Rack::Test::UploadedFile.new(
      Rails.root.join("spec/support/macbookair_stickered.jpg"),
      "image/jpeg"
    )
  end

  describe "#resolve_picture_upload" do
    it "creates a new picture with converted image, date, visibility, and event" do
      pic = nil
      expect {
        pic = resolver.resolve_picture_upload(picture_file: uploaded_file, picture_name: "Upload Name")
      }.to change { Picture.count }.by(1)

      expect(pic).to be_persisted
      expect(pic.name).to eq("Upload Name")
      expect(pic.team).to eq(team)
      expect(pic.visibility).to eq("published")
    end

    it "raises ActiveRecord::RecordInvalid and adds error to parent when upload fails validation" do
      expect {
        resolver.resolve_picture_upload(picture_file: uploaded_file, picture_name: "a" * 300)
      }.to raise_error(ActiveRecord::RecordInvalid)

      expect(parent.errors[:picture_file]).to be_present
    end
  end

  describe "#find_existing_picture" do
    let!(:existing_picture) { FactoryBot.create(:picture, team: team, name: "Sunset") }

    it "finds existing picture by id" do
      expect(resolver.find_existing_picture(existing_picture.id)).to eq(existing_picture)
    end

    it "finds existing picture by urlsafe_id" do
      expect(resolver.find_existing_picture(existing_picture.urlsafe_id)).to eq(existing_picture)
    end

    it "does not find picture from another team" do
      other_team = FactoryBot.create(:team)
      other_picture = FactoryBot.create(:picture, team: other_team)

      expect(resolver.find_existing_picture(other_picture.id)).to be_nil
    end
  end

  describe "#resolve_location" do
    it "creates a new location when name/address is provided" do
      loc = nil
      expect {
        loc = resolver.resolve_location(
          location_name: "Mount Olympus",
          location_address: "Thessaly, Greece",
          location_country_code: "gr",
          location_url: "https://maps.example.com"
        )
      }.to change { Location.count }.by(1)

      expect(loc).to be_persisted
      expect(loc.name).to eq("Mount Olympus")
      expect(loc.country_code).to be_present
      expect(loc.team).to eq(team)
      expect(loc.visibility).to eq("published")
    end

    it "finds existing location by ID when no name is provided" do
      existing_loc = FactoryBot.create(:location, team: team)
      expect(resolver.resolve_location(location_id: existing_loc.id)).to eq(existing_loc)
    end

    it "raises ActiveRecord::RecordInvalid when location validation fails" do
      expect {
        resolver.resolve_location(
          location_name: "Bad Loc",
          location_country_code: "invalid_code"
        )
      }.to raise_error(ActiveRecord::RecordInvalid)

      expect(parent.errors[:location_name]).to be_present
    end
  end

  describe "#resolve_thought" do
    it "creates a new thought when text is provided" do
      thot = nil
      expect {
        thot = resolver.resolve_thought(thought_text: "Clear mind")
      }.to change { Thought.count }.by(1)

      expect(thot).to be_persisted
      expect(thot.text).to eq("Clear mind")
      expect(thot.team).to eq(team)
      expect(thot.visibility).to eq("published")
    end

    it "finds existing thought by ID when no text is provided" do
      existing_thought = FactoryBot.create(:thought, team: team)
      expect(resolver.resolve_thought(thought_id: existing_thought.id)).to eq(existing_thought)
    end

    it "raises ActiveRecord::RecordInvalid when thought validation fails" do
      expect {
        resolver.resolve_thought(thought_text: "a" * 2000)
      }.to raise_error(ActiveRecord::RecordInvalid)

      expect(parent.errors[:thought_text]).to be_present
    end
  end

  describe "#resolve_weblink" do
    it "creates a new weblink when url/name is provided" do
      link = nil
      expect {
        link = resolver.resolve_weblink(
          weblink_name: "Example",
          weblink_url: "https://example.com",
          weblink_description: "Great site"
        )
      }.to change { Weblink.count }.by(1)

      expect(link).to be_persisted
      expect(link.name).to eq("Example")
      expect(link.url).to eq("https://example.com")
      expect(link.team).to eq(team)
      expect(link.visibility).to eq("published")
    end

    it "finds existing weblink by ID when no url/name is provided" do
      existing_weblink = FactoryBot.create(:weblink, team: team)
      expect(resolver.resolve_weblink(weblink_id: existing_weblink.id)).to eq(existing_weblink)
    end

    it "raises ActiveRecord::RecordInvalid when weblink validation fails" do
      FactoryBot.create(:weblink, team: team, url: "https://duplicate.com")

      expect {
        resolver.resolve_weblink(
          weblink_name: "Duplicate",
          weblink_url: "https://duplicate.com"
        )
      }.to raise_error(ActiveRecord::RecordInvalid)

      expect(parent.errors[:weblink_url]).to be_present
    end
  end
end
