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
      visibility: "draft",
    }
  end

  describe "associations" do
    it "has many distinct chronicles through chronicle_entries" do
      weblink.save!
      chronicle1 = FactoryBot.create(:chronicle, team: team)
      chronicle2 = FactoryBot.create(:chronicle, team: team)

      FactoryBot.create(:chronicle_entry, chronicle: chronicle1, team: team, entry: weblink, position: 1)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle1, team: team, entry: weblink, position: 2)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle2, team: team, entry: weblink, position: 1)

      expect(weblink.chronicles).to contain_exactly(chronicle1, chronicle2)
    end

    it "destroys associated chronicle_entries when weblink is destroyed" do
      weblink.save!
      chronicle = FactoryBot.create(:chronicle, team: team)
      entry = FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: weblink)

      expect { weblink.destroy! }.to change { ChronicleEntry.count }.by(-1)
      expect { entry.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "nullifies memory reference when destroyed" do
      link = described_class.create!(valid_attributes)
      memory = FactoryBot.create(:memory, team: team, weblink: link)

      expect(memory.reload.weblink_id).to eq(link.id)
      link.destroy!
      expect(memory.reload.weblink_id).to be_nil
    end
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

  describe "search index" do
    it "creates a PgSearch::Document when saved" do
      expect { weblink.save! }.to change { PgSearch::Document.where(searchable_type: "Weblink").count }.by(1)
    end

    it "indexes the name in the document content" do
      weblink.save!
      expect(weblink.pg_search_document.content).to include(weblink.name)
    end

    it "sets team_id on the document" do
      weblink.save!
      expect(weblink.pg_search_document.team_id).to eq(team.id)
    end

    it "returns the record via the searchable association" do
      weblink.save!
      expect(weblink.pg_search_document.searchable).to eq(weblink)
    end
  end

  describe "parent visibility constraints" do
    it "prohibits reducing visibility when weblink belongs to a published chronicle" do
      weblink.visibility = "published"
      weblink.save!

      chronicle = FactoryBot.create(:chronicle, team: team, name: "Resource Guide", visibility: "published")
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: weblink)

      weblink.visibility = "internal"
      expect(weblink).not_to be_valid
      expect(weblink.errors[:visibility]).to be_present
      expect(weblink.errors[:visibility].first).to include("cannot be limited to 'internal'")
      expect(weblink.errors[:visibility].first).to include("Resource Guide")
    end

    it "prohibits reducing visibility when weblink belongs to a published memory" do
      weblink.visibility = "published"
      weblink.save!

      FactoryBot.create(:memory, team: team, memo: "Article bookmark", weblink: weblink, visibility: "published")

      weblink.visibility = "internal"
      expect(weblink).not_to be_valid
      expect(weblink.errors[:visibility]).to be_present
      expect(weblink.errors[:visibility].first).to include("cannot be limited to 'internal'")
      expect(weblink.errors[:visibility].first).to include("Article bookmark")
    end
  end
end
