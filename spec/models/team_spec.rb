# frozen_string_literal: true

require "rails_helper"

RSpec.describe Team, type: :model do
  subject(:team) { described_class.new(valid_attributes) }

  let(:valid_attributes) do
    {
      name: "VanLife Adventurers",
    }
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(team).to be_valid
    end

    it "validates name presence and length between 7 and 72 characters" do
      team.name = "Short"
      expect(team).not_to be_valid
      expect(team.errors[:name]).to be_present

      team.name = "A" * 73
      expect(team).not_to be_valid

      team.name = "Valid Team Name"
      expect(team).to be_valid
    end

    it "validates name uniqueness" do
      team.save!
      duplicate = described_class.new(name: "VanLife Adventurers")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to be_present
    end
  end

  describe "normalizations" do
    it "strips whitespace from name" do
      created_team = described_class.create!(name: "   VanLife Adventurers   ")
      expect(created_team.name).to eq("VanLife Adventurers")
    end
  end

  describe "associations and cascading deletions" do
    let!(:saved_team) { described_class.create!(valid_attributes) }
    let!(:user) { FactoryBot.create(:user) }
    let!(:member) { Member.create!(team: saved_team, user: user, roles: %w[owner]) }
    let!(:location) { FactoryBot.create(:location, team: saved_team) }
    let!(:picture) { FactoryBot.create(:picture, team: saved_team) }
    let!(:thought) { FactoryBot.create(:thought, team: saved_team) }
    let!(:weblink) { FactoryBot.create(:weblink, team: saved_team) }
    let!(:memory) { FactoryBot.create(:memory, team: saved_team, location:, picture:, thought:, weblink:) }

    it "has many associated content records" do
      expect(saved_team.members).to include(member)
      expect(saved_team.locations).to include(location)
      expect(saved_team.pictures).to include(picture)
      expect(saved_team.thoughts).to include(thought)
      expect(saved_team.weblinks).to include(weblink)
      expect(saved_team.memories).to include(memory)
      expect(saved_team.users).to include(user)
    end

    it "cascades deletion to all child records when team is destroyed" do
      expect {
        saved_team.destroy!
      }.to change { Member.count }.by(-1)
        .and change { Location.count }.by(-1)
        .and change { Picture.count }.by(-1)
        .and change { Thought.count }.by(-1)
        .and change { Weblink.count }.by(-1)
        .and change { Memory.count }.by(-1)

      expect(User.find_by(id: user.id)).to be_present # User is not deleted
    end
  end
end
