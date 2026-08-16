# frozen_string_literal: true

require "rails_helper"

RSpec.describe MemoryInsightAttacher do
  let(:team) { FactoryBot.create(:team) }
  let(:user) { FactoryBot.create(:user) }
  let!(:memory) { FactoryBot.create(:memory, team: team, memo: "Enjoying the seaside morning", visibility: "internal") }

  let(:uploaded_file) do
    Rack::Test::UploadedFile.new(
      Rails.root.join("spec/support/macbookair_stickered.jpg"),
      "image/jpeg"
    )
  end

  describe ".extract_insight_params!" do
    it "extracts insight parameters from attributes and modifies the hash in place" do
      attrs = {
        memo: "A memorable day",
        visibility: "internal",
        picture_id: "pic_123",
        location_name: "Mount Olympus",
        thought_text: "Clear mind",
        weblink_url: "https://example.com",
      }

      extracted = described_class.extract_insight_params!(attrs)

      expect(attrs).to eq({
        memo: "A memorable day",
        visibility: "internal",
      })
      expect(extracted).to eq({
        picture_id: "pic_123",
        location_name: "Mount Olympus",
        thought_text: "Clear mind",
        weblink_url: "https://example.com",
      })
    end
  end

  describe ".call" do
    it "returns without error when params are blank" do
      expect {
        described_class.call(memory: memory, params: {}, user: user)
      }.not_to(change { memory.reload.attributes })
    end

    context "when attaching pictures" do
      let!(:existing_picture) { FactoryBot.create(:picture, team: team, name: "Sunset") }

      it "attaches an existing picture by ID" do
        described_class.call(memory: memory, params: { picture_id: existing_picture.id }, user: user)

        expect(memory.reload.picture).to eq(existing_picture)
      end

      it "attaches an existing picture by urlsafe_id" do
        described_class.call(memory: memory, params: { picture_id: existing_picture.urlsafe_id }, user: user)

        expect(memory.reload.picture).to eq(existing_picture)
      end

      it "uploads and attaches a new picture file" do
        expect {
          described_class.call(
            memory: memory,
            params: { picture_file: uploaded_file, picture_name: "Fresh Photo" },
            user: user
          )
        }.to change { Picture.count }.by(1)

        expect(memory.reload.picture).to be_present
        expect(memory.picture.name).to eq("Fresh Photo")
        expect(memory.picture.team).to eq(team)
      end

      it "does not attach a picture from another team" do
        other_team = FactoryBot.create(:team)
        other_picture = FactoryBot.create(:picture, team: other_team)

        described_class.call(memory: memory, params: { picture_id: other_picture.id }, user: user)

        expect(memory.reload.picture).to be_nil
      end
    end

    context "when attaching locations" do
      let(:existing_location) { FactoryBot.create(:location, team: team, name: "Beach") }

      it "attaches an existing location by ID" do
        described_class.call(memory: memory, params: { location_id: existing_location.id }, user: user)

        expect(memory.reload.location).to eq(existing_location)
      end

      it "creates and attaches a new location inline" do
        expect {
          described_class.call(
            memory: memory,
            params: {
              location_name: "Mount Olympus",
              location_address: "Thessaly, Greece",
              location_country_code: "gr",
            },
            user: user
          )
        }.to change { Location.count }.by(1)

        expect(memory.reload.location.name).to eq("Mount Olympus")
        expect(memory.location.team).to eq(team)
      end
    end

    context "when attaching thoughts" do
      let(:existing_thought) { FactoryBot.create(:thought, team: team, text: "Existing reflection") }

      it "attaches an existing thought by ID" do
        described_class.call(memory: memory, params: { thought_id: existing_thought.id }, user: user)

        expect(memory.reload.thought).to eq(existing_thought)
      end

      it "creates and attaches a new thought inline" do
        expect {
          described_class.call(
            memory: memory,
            params: { thought_text: "Reflecting by the ocean" },
            user: user
          )
        }.to change { Thought.count }.by(1)

        expect(memory.reload.thought.text).to eq("Reflecting by the ocean")
        expect(memory.thought.team).to eq(team)
      end
    end

    context "when attaching weblinks" do
      let(:existing_weblink) { FactoryBot.create(:weblink, team: team, name: "Guide", url: "https://guide.com") }

      it "attaches an existing weblink by ID" do
        described_class.call(memory: memory, params: { weblink_id: existing_weblink.id }, user: user)

        expect(memory.reload.weblink).to eq(existing_weblink)
      end

      it "creates and attaches a new weblink inline" do
        expect {
          described_class.call(
            memory: memory,
            params: {
              weblink_name: "Travel Map",
              weblink_url: "https://maps.example.com",
            },
            user: user
          )
        }.to change { Weblink.count }.by(1)

        expect(memory.reload.weblink.name).to eq("Travel Map")
        expect(memory.weblink.team).to eq(team)
      end
    end

    context "when both existing ID and new creation parameters are submitted (Option C mutual exclusivity)" do
      it "raises ActiveRecord::RecordInvalid and adds error for picture conflict" do
        existing_picture = FactoryBot.create(:picture, team: team)

        expect {
          described_class.call(
            memory: memory,
            params: { picture_id: existing_picture.id, picture_file: uploaded_file },
            user: user
          )
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect(memory.errors[:picture_id]).to include(
          "Please either select an existing picture or upload a new picture, not both"
        )
      end

      it "raises ActiveRecord::RecordInvalid and adds error for location conflict" do
        existing_location = FactoryBot.create(:location, team: team)

        expect {
          described_class.call(
            memory: memory,
            params: { location_id: existing_location.id, location_name: "New Place" },
            user: user
          )
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect(memory.errors[:location_id]).to include(
          "Please either select an existing location or create a new location, not both"
        )
      end

      it "raises ActiveRecord::RecordInvalid and adds error for thought conflict" do
        existing_thought = FactoryBot.create(:thought, team: team)

        expect {
          described_class.call(
            memory: memory,
            params: { thought_id: existing_thought.id, thought_text: "New reflection" },
            user: user
          )
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect(memory.errors[:thought_id]).to include(
          "Please either select an existing thought or create a new thought, not both"
        )
      end

      it "raises ActiveRecord::RecordInvalid and adds error for weblink conflict" do
        existing_weblink = FactoryBot.create(:weblink, team: team)

        expect {
          described_class.call(
            memory: memory,
            params: { weblink_id: existing_weblink.id, weblink_url: "https://example.com" },
            user: user
          )
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect(memory.errors[:weblink_id]).to include(
          "Please either select an existing weblink or create a new weblink, not both"
        )
      end
    end

    context "when an attached insight fails validation" do
      it "raises ActiveRecord::RecordInvalid and adds error to memory when location is invalid" do
        expect {
          described_class.call(
            memory: memory,
            params: {
              location_name: "Invalid Country Place",
              location_country_code: "invalid_code",
            },
            user: user
          )
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect(Location.count).to eq(0)
        expect(memory.errors[:location_name]).to be_present
      end

      it "raises ActiveRecord::RecordInvalid and adds error to memory when thought is invalid" do
        expect {
          described_class.call(
            memory: memory,
            params: { thought_text: "a" * 2000 },
            user: user
          )
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect(Thought.count).to eq(0)
        expect(memory.errors[:thought_text]).to be_present
      end
    end
  end
end
