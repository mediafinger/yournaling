# frozen_string_literal: true

require "rails_helper"

RSpec.describe Weblink, type: :model do
  subject(:weblink) { described_class.new(valid_attributes) }

  let(:team) { FactoryBot.create(:team) }
  let(:valid_attributes) do
    {
      team: team,
      name: "Vanlife Route Planning Guide",
      url: "route-planner.example.com/tips",
      visibility: "internal",
    }
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(weblink).to be_valid
    end

    it "validates presence of name" do
      weblink.name = ""
      expect(weblink).not_to be_valid
      expect(weblink.errors[:name]).to be_present
    end

    it "validates url uniqueness scoped to team" do
      weblink.save!
      duplicate = described_class.new(valid_attributes)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:url]).to be_present

      other_team = FactoryBot.create(:team)
      duplicate.team = other_team
      expect(duplicate).to be_valid
    end

    it "validates visibility inclusion" do
      weblink.visibility = "forbidden_state"
      expect(weblink).not_to be_valid
      expect(weblink.errors[:visibility]).to be_present
    end
  end

  describe "normalizations" do
    it "auto-prefixes url with https://" do
      link = described_class.create!(valid_attributes.merge(url: "wildcamping.example.com/spots"))
      expect(link.url).to eq("https://wildcamping.example.com/spots")
    end

    it "strips whitespace from name" do
      link = described_class.create!(valid_attributes.merge(name: "   Camp Spots in Pyrenees   "))
      expect(link.name).to eq("Camp Spots in Pyrenees")
    end
  end

  describe "associations" do
    it "nullifies memory reference when destroyed" do
      link = described_class.create!(valid_attributes)
      memory = FactoryBot.create(:memory, team: team, weblink: link)

      expect(memory.reload.weblink_id).to eq(link.id)
      link.destroy!
      expect(memory.reload.weblink_id).to be_nil
    end
  end
end
