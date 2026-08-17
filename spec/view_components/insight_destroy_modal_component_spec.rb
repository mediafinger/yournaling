# frozen_string_literal: true

require "rails_helper"

RSpec.describe InsightDestroyModalComponent, type: :component do
  let(:team) { FactoryBot.create(:team) }
  let(:user) { FactoryBot.create(:user) }
  let(:picture) { FactoryBot.create(:picture, team: team, name: "Sunset Beach") }

  it "renders unblocked destroy button when insight is unreferenced" do
    render_inline(described_class.new(insight: picture, name: "picture"))

    expect(page).to have_text("Are you sure you want to destroy this picture?")
    expect(page).to have_button("Destroy Insight")
    expect(page).to have_no_css("button.contrast[disabled]")
  end

  it "renders disabled destroy button and lists referencing chronicles" do
    chronicle = FactoryBot.create(:chronicle, team: team, name: "Summer Holidays")
    FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: picture)

    render_inline(described_class.new(insight: picture, name: "picture"))

    expect(page).to have_text("This picture cannot be destroyed because it is still referenced by other content:")
    expect(page).to have_text("Chronicles:")
    expect(page).to have_link("Summer Holidays")
    expect(page).to have_css("button.contrast[disabled]")
    expect(page).to have_button("Close")
  end

  it "renders disabled destroy button and lists referencing memories" do
    FactoryBot.create(:memory, team: team, picture: picture, memo: "Golden hour memories")

    render_inline(described_class.new(insight: picture, name: "picture"))

    expect(page).to have_text("This picture cannot be destroyed because it is still referenced by other content:")
    expect(page).to have_text("Memories:")
    expect(page).to have_link("Golden hour memories")
    expect(page).to have_css("button.contrast[disabled]")
    expect(page).to have_button("Close")
  end
end
