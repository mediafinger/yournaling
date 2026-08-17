# frozen_string_literal: true

require "rails_helper"

RSpec.describe Publishable, type: :model do
  let(:team) { FactoryBot.create(:team) }

  describe "Chronicle lifecycle synchronization" do
    it "creates a publishing record when chronicle is created with published visibility" do
      chronicle = FactoryBot.create(:chronicle, team: team, visibility: "published")

      expect(chronicle.publishing).to be_present
      expect(chronicle.publishing.visibility).to eq("published")
      expect(chronicle.publishing.published_count).to eq(1)
      expect(chronicle.publishing.first_published_at).to be_within(5.seconds).of(Time.current)
      expect(chronicle.publishing.republished_at).to be_within(5.seconds).of(Time.current)
    end

    it "creates a publishing record when chronicle visibility changes from internal to published" do
      chronicle = FactoryBot.create(:chronicle, team: team, visibility: "internal")
      expect(chronicle.publishing).to be_nil

      chronicle.update!(visibility: "published")
      chronicle.reload

      expect(chronicle.publishing).to be_present
      expect(chronicle.publishing.visibility).to eq("published")
      expect(chronicle.publishing.published_count).to eq(1)
    end

    it "updates publishing visibility and increments published_count on republishing" do
      chronicle = FactoryBot.create(:chronicle, team: team, visibility: "published")
      initial_published_at = chronicle.publishing.first_published_at

      # Change to internal
      chronicle.update!(visibility: "internal")
      expect(chronicle.publishing.reload.visibility).to eq("internal")
      expect(chronicle.publishing.published_count).to eq(1)

      # Republish after delay
      travel 1.hour do
        chronicle.update!(visibility: "published")
        publishing = chronicle.publishing.reload

        expect(publishing.visibility).to eq("published")
        expect(publishing.published_count).to eq(2)
        expect(publishing.first_published_at).to eq(initial_published_at)
        expect(publishing.republished_at).to be > initial_published_at
      end
    end

    it "destroys publishing record when chronicle is destroyed" do
      chronicle = FactoryBot.create(:chronicle, team: team, visibility: "published")
      publishing = chronicle.publishing

      expect { chronicle.destroy! }.to change { Publishing.count }.by(-1)
      expect { publishing.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "Memory lifecycle synchronization" do
    it "creates a publishing record when memory is created with published visibility" do
      memory = FactoryBot.create(:memory, team: team, visibility: "published")

      expect(memory.publishing).to be_present
      expect(memory.publishing.visibility).to eq("published")
      expect(memory.publishing.published_count).to eq(1)
    end

    it "syncs publishing record when memory visibility changes" do
      memory = FactoryBot.create(:memory, team: team, visibility: "internal")
      expect(memory.publishing).to be_nil

      memory.update!(visibility: "published")
      expect(memory.publishing).to be_present
      expect(memory.publishing.visibility).to eq("published")

      memory.update!(visibility: "archived")
      expect(memory.publishing.reload.visibility).to eq("archived")
    end
  end
end
