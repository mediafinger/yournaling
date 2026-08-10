# frozen_string_literal: true

require "rails_helper"

RSpec.describe Current, type: :model do
  let(:user) { FactoryBot.create(:user) }
  let(:team) { FactoryBot.create(:team) }
  let(:member) { Member.create!(team: team, user: user, roles: %w[owner]) }

  after do
    described_class.reset
  end

  it "holds per-request contextual attributes" do
    described_class.user = user
    described_class.team = team
    described_class.member = member
    described_class.module_name = "current_team"
    described_class.path = "/current_team/memories"
    described_class.request_id = "req_12345"

    expect(described_class.user).to eq(user)
    expect(described_class.team).to eq(team)
    expect(described_class.member).to eq(member)
    expect(described_class.module_name).to eq("current_team")
    expect(described_class.path).to eq("/current_team/memories")
    expect(described_class.request_id).to eq("req_12345")
  end

  it "resets attributes cleanly" do
    described_class.user = user
    described_class.reset
    expect(described_class.user).to be_nil
  end
end
