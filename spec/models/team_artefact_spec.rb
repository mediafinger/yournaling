# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeamArtefact, type: :model do
  let(:team) { FactoryBot.create(:team) }
  let(:other_team) { FactoryBot.create(:team) }

  it "aggregates posts, insights, and members from the database view" do
    chronicle = FactoryBot.create(:chronicle, team: team, name: "Chronicle 1", visibility: "draft")
    memory = FactoryBot.create(:memory, team: team, memo: "Memory 1", visibility: "internal")
    picture = FactoryBot.create(:picture, team: team, name: "Picture 1", visibility: "published")
    location = FactoryBot.create(:location, team: team, name: "Location 1", visibility: "archived")
    thought = FactoryBot.create(:thought, team: team, text: "Thought 1", visibility: "draft")
    weblink = FactoryBot.create(:weblink, team: team, name: "Weblink 1", visibility: "internal")
    member = Member.find_by(team: team) || FactoryBot.create(:member, team: team)

    artefacts = described_class.for_team(team)

    expect(artefacts.pluck(:artefact_type)).to include(
      "Chronicle", "Memory", "Picture", "Location", "Thought", "Weblink", "Member"
    )
    expect(artefacts.map(&:artefact)).to include(chronicle, memory, picture, location, thought, weblink, member)
  end

  it "isolates items to the specified team" do
    chronicle_in_team = FactoryBot.create(:chronicle, team: team)
    chronicle_in_other = FactoryBot.create(:chronicle, team: other_team)

    expect(described_class.for_team(team).map(&:artefact)).to include(chronicle_in_team)
    expect(described_class.for_team(team).map(&:artefact)).not_to include(chronicle_in_other)
  end

  it "orders items by updated_at DESC in .chronological" do
    item1 = FactoryBot.create(:thought, team: team, text: "Old thought", updated_at: 2.hours.ago)
    item2 = FactoryBot.create(:thought, team: team, text: "New thought", updated_at: 10.minutes.ago)

    results = described_class.for_team(team).chronological.where(artefact_id: [item1.id, item2.id])
    expect(results.first.artefact_id).to eq(item2.id)
    expect(results.second.artefact_id).to eq(item1.id)
  end

  it "is readonly" do
    chronicle = FactoryBot.create(:chronicle, team: team)
    artefact = described_class.find_by(artefact_id: chronicle.id)

    expect(artefact).to be_readonly
    expect { artefact.save }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end
end
