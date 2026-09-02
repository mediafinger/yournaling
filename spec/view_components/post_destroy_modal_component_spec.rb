# frozen_string_literal: true

require "rails_helper"

RSpec.describe PostDestroyModalComponent, type: :component do
  let(:team) { FactoryBot.create(:team) }

  it "renders the two destroy paths for a memory" do
    memory = FactoryBot.create(:memory, team: team, memo: "A day at the coast")

    render_inline(described_class.new(post: memory, name: "memory"))

    expect(page).to have_button("Destroy this memory")
    expect(page).to have_text("Are you sure you want to destroy")
    expect(page).to have_button("Destroy Memory Only")
    expect(page).to have_button("Destroy & Delete Orphaned Insights")
  end

  it "renders the two destroy paths for a chronicle" do
    chronicle = FactoryBot.create(:chronicle, team: team, name: "The Coast Year")

    render_inline(described_class.new(post: chronicle, name: "chronicle"))

    expect(page).to have_button("Destroy this chronicle")
    expect(page).to have_text("The Coast Year")
    expect(page).to have_button("Destroy Chronicle Only")
    expect(page).to have_button("Destroy & Delete Orphaned Insights")
  end
end
