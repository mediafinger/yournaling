# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChronicleInsightAttacher do
  let(:team) { FactoryBot.create(:team) }
  let(:user) { FactoryBot.create(:user) }
  let(:chronicle) { FactoryBot.create(:chronicle, team: team, start_date: Date.current, visibility: "published") }
  let(:uploaded_file) do
    Rack::Test::UploadedFile.new(
      Rails.root.join("spec/support/macbookair_stickered.jpg"),
      "image/jpeg"
    )
  end

  describe ".extract_insight_params!" do
    it "extracts insight parameters from attributes and modifies the hash in place" do
      attrs = {
        name: "Malaga Chronicles",
        notice: "Some long notice description here.",
        picture_id: "pic_123",
        location_id: "loc_123",
        thought_text: "Great journey ahead",
        weblink_url: "https://example.com",
      }

      extracted = described_class.extract_insight_params!(attrs)

      expect(attrs).to eq({
        name: "Malaga Chronicles",
        notice: "Some long notice description here.",
      })
      expect(extracted).to eq({
        picture_id: "pic_123",
        location_id: "loc_123",
        thought_text: "Great journey ahead",
        weblink_url: "https://example.com",
      })
    end
  end

  describe ".call" do
    it "returns without error when params are blank" do
      expect {
        described_class.call(chronicle: chronicle, params: {}, user: user)
      }.not_to(change { chronicle.entries.count })
    end

    context "when attaching pictures" do
      let(:existing_picture) { FactoryBot.create(:picture, team: team, name: "Existing Picture", visibility: "internal") }

      it "attaches an existing picture by ID and aligns visibility" do
        expect {
          described_class.call(chronicle: chronicle, params: { picture_id: existing_picture.id }, user: user)
        }.to change { chronicle.entries.count }.by(1)

        entry = chronicle.entries.last
        expect(entry.entry).to eq(existing_picture)
        expect(existing_picture.reload.visibility).to eq("published")
      end

      it "attaches an existing picture by urlsafe_id" do
        expect {
          described_class.call(chronicle: chronicle, params: { picture_id: existing_picture.urlsafe_id }, user: user)
        }.to change { chronicle.entries.count }.by(1)

        expect(chronicle.entries.last.entry).to eq(existing_picture)
      end

      it "uploads and attaches a new picture file" do
        expect {
          described_class.call(
            chronicle: chronicle,
            params: { picture_file: uploaded_file, picture_name: "Fresh Pic" },
            user: user
          )
        }.to change { Picture.count }.by(1).and change { chronicle.entries.count }.by(1)

        new_pic = Picture.last
        expect(new_pic.name).to eq("Fresh Pic")
        expect(new_pic.team).to eq(team)
        expect(new_pic.visibility).to eq("published")
        expect(chronicle.entries.last.entry).to eq(new_pic)
      end

      it "does not attach a picture from another team" do
        other_team = FactoryBot.create(:team)
        other_picture = FactoryBot.create(:picture, team: other_team)

        expect {
          described_class.call(chronicle: chronicle, params: { picture_id: other_picture.id }, user: user)
        }.not_to(change { chronicle.entries.count })
      end
    end

    context "when attaching locations" do
      let(:existing_location) { FactoryBot.create(:location, team: team, name: "Sunset Beach", visibility: "internal") }

      it "attaches an existing location by ID and aligns visibility" do
        expect {
          described_class.call(chronicle: chronicle, params: { location_id: existing_location.id }, user: user)
        }.to change { chronicle.entries.count }.by(1)

        expect(chronicle.entries.last.entry).to eq(existing_location)
        expect(existing_location.reload.visibility).to eq("published")
      end

      it "creates and attaches a new location" do
        expect {
          described_class.call(
            chronicle: chronicle,
            params: {
              location_name: "Mount Olympus",
              location_address: "Thessaly, Greece",
              location_country_code: "gr",
              location_url: "https://maps.example.com/olympus",
            },
            user: user
          )
        }.to change { Location.count }.by(1).and change { chronicle.entries.count }.by(1)

        new_loc = chronicle.entries.last.entry
        expect(new_loc.name).to eq("Mount Olympus")
        expect(new_loc.address).to eq("Thessaly, Greece")
        expect(new_loc.country_code).to be_present
        expect(new_loc.team).to eq(team)
        expect(new_loc.visibility).to eq("published")
      end

      it "does not attach a location from another team" do
        other_team = FactoryBot.create(:team)
        other_location = FactoryBot.create(:location, team: other_team)

        expect {
          described_class.call(chronicle: chronicle, params: { location_id: other_location.id }, user: user)
        }.not_to(change { chronicle.entries.count })
      end
    end

    context "when attaching thoughts" do
      let(:existing_thought) { FactoryBot.create(:thought, team: team, text: "Existing thought", visibility: "internal") }

      it "attaches an existing thought by ID and aligns visibility" do
        expect {
          described_class.call(chronicle: chronicle, params: { thought_id: existing_thought.id }, user: user)
        }.to change { chronicle.entries.count }.by(1)

        expect(chronicle.entries.last.entry).to eq(existing_thought)
        expect(existing_thought.reload.visibility).to eq("published")
      end

      it "creates and attaches a new thought" do
        expect {
          described_class.call(
            chronicle: chronicle,
            params: { thought_text: "Reflecting on the journey ahead" },
            user: user
          )
        }.to change { Thought.count }.by(1).and change { chronicle.entries.count }.by(1)

        new_thought = chronicle.entries.last.entry
        expect(new_thought.text).to eq("Reflecting on the journey ahead")
        expect(new_thought.team).to eq(team)
        expect(new_thought.visibility).to eq("published")
      end

      it "does not attach a thought from another team" do
        other_team = FactoryBot.create(:team)
        other_thought = FactoryBot.create(:thought, team: other_team)

        expect {
          described_class.call(chronicle: chronicle, params: { thought_id: other_thought.id }, user: user)
        }.not_to(change { chronicle.entries.count })
      end
    end

    context "when attaching weblinks" do
      let(:existing_weblink) { FactoryBot.create(:weblink, team: team, name: "Existing Link", url: "https://existing.com", visibility: "internal") }

      it "attaches an existing weblink by ID and aligns visibility" do
        expect {
          described_class.call(chronicle: chronicle, params: { weblink_id: existing_weblink.id }, user: user)
        }.to change { chronicle.entries.count }.by(1)

        expect(chronicle.entries.last.entry).to eq(existing_weblink)
        expect(existing_weblink.reload.visibility).to eq("published")
      end

      it "creates and attaches a new weblink" do
        expect {
          described_class.call(
            chronicle: chronicle,
            params: {
              weblink_name: "Travel Guide",
              weblink_url: "https://travelguide.example.com",
              weblink_description: "Helpful guide",
            },
            user: user
          )
        }.to change { Weblink.count }.by(1).and change { chronicle.entries.count }.by(1)

        new_link = chronicle.entries.last.entry
        expect(new_link.name).to eq("Travel Guide")
        expect(new_link.url).to eq("https://travelguide.example.com")
        expect(new_link.team).to eq(team)
        expect(new_link.visibility).to eq("published")
      end

      it "does not attach a weblink from another team" do
        other_team = FactoryBot.create(:team)
        other_weblink = FactoryBot.create(:weblink, team: other_team)

        expect {
          described_class.call(chronicle: chronicle, params: { weblink_id: other_weblink.id }, user: user)
        }.not_to(change { chronicle.entries.count })
      end
    end

    context "with multiple mixed attachments" do
      let(:picture) { FactoryBot.create(:picture, team: team) }
      let(:location) { FactoryBot.create(:location, team: team) }

      it "attaches all provided insights in a single call" do
        params = {
          picture_id: picture.id,
          location_id: location.id,
          thought_text: "Batch thought",
          weblink_url: "https://batch.example.com",
          weblink_name: "Batch Link",
        }

        expect {
          described_class.call(chronicle: chronicle, params: params, user: user)
        }.to change { chronicle.entries.count }.by(4)
          .and change { Thought.count }.by(1)
          .and change { Weblink.count }.by(1)

        expect(chronicle.pictures).to include(picture)
        expect(chronicle.locations).to include(location)
        expect(chronicle.thoughts.pluck(:text)).to include("Batch thought")
        expect(chronicle.weblinks.pluck(:name)).to include("Batch Link")
      end
    end
  end
end
