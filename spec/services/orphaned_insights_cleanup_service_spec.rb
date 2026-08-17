# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrphanedInsightsCleanupService, type: :service do
  let(:team) { FactoryBot.create(:team) }
  let(:user) { FactoryBot.create(:user) }

  describe ".call for Memory" do
    let(:unshared_picture) { FactoryBot.create(:picture, team: team) }
    let(:unshared_thought) { FactoryBot.create(:thought, team: team) }
    let(:shared_location) { FactoryBot.create(:location, team: team) }
    let(:shared_weblink) { FactoryBot.create(:weblink, team: team) }

    let!(:memory_to_destroy) do
      FactoryBot.create(
        :memory,
        team: team,
        picture: unshared_picture,
        thought: unshared_thought,
        location: shared_location,
        weblink: shared_weblink
      )
    end

    let!(:other_memory) do
      FactoryBot.create(:memory, team: team, location: shared_location)
    end

    let!(:other_chronicle) do
      chronicle = FactoryBot.create(:chronicle, team: team)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: shared_weblink)
      chronicle
    end

    it "destroys memory and only unshared insights" do
      expect {
        described_class.call(post: memory_to_destroy, team: team, user: user)
      }.to change { Memory.count }.by(-1)
        .and change { Picture.count }.by(-1)
        .and change { Thought.count }.by(-1)
        .and change { Location.count }.by(0)
        .and change { Weblink.count }.by(0)

      expect(Picture.find_by(id: unshared_picture.id)).to be_nil
      expect(Thought.find_by(id: unshared_thought.id)).to be_nil
      expect(Location.find_by(id: shared_location.id)).to eq(shared_location)
      expect(Weblink.find_by(id: shared_weblink.id)).to eq(shared_weblink)
    end
  end

  describe ".call for Chronicle" do
    let(:unshared_picture) { FactoryBot.create(:picture, team: team) }
    let(:unshared_thought) { FactoryBot.create(:thought, team: team) }
    let(:shared_location) { FactoryBot.create(:location, team: team) }
    let(:shared_weblink) { FactoryBot.create(:weblink, team: team) }

    let!(:chronicle_to_destroy) do
      chronicle = FactoryBot.create(:chronicle, team: team)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: unshared_picture, position: 1)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: unshared_thought, position: 2)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: shared_location, position: 3)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: shared_weblink, position: 4)
      chronicle
    end

    let!(:other_chronicle) do
      chronicle = FactoryBot.create(:chronicle, team: team)
      FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: shared_location, position: 1)
      chronicle
    end

    let!(:other_memory) do
      FactoryBot.create(:memory, team: team, weblink: shared_weblink)
    end

    it "destroys chronicle and only unshared insights" do
      expect {
        described_class.call(post: chronicle_to_destroy, team: team, user: user)
      }.to change { Chronicle.count }.by(-1)
        .and change { Picture.count }.by(-1)
        .and change { Thought.count }.by(-1)
        .and change { Location.count }.by(0)
        .and change { Weblink.count }.by(0)

      expect(Picture.find_by(id: unshared_picture.id)).to be_nil
      expect(Thought.find_by(id: unshared_thought.id)).to be_nil
      expect(Location.find_by(id: shared_location.id)).to eq(shared_location)
      expect(Weblink.find_by(id: shared_weblink.id)).to eq(shared_weblink)
    end
  end
end
