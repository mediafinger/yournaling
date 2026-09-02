# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Insight Destruction with Reference Checking", type: :system do
  let(:user) { FactoryBot.create(:user, email: "photographer@example.com", name: "Alex Lens") }
  let(:team) { FactoryBot.create(:team, name: "Photo Team") }
  let!(:member) { Member.create!(team: team, user: user, roles: %w[owner]) }

  let!(:unreferenced_picture) { FactoryBot.create(:picture, team: team, name: "Solitary Lake") }
  let!(:referenced_picture) { FactoryBot.create(:picture, team: team, name: "Crowded Beach") }
  let!(:referenced_thought) { FactoryBot.create(:thought, team: team, text: "Reflecting by the shore") }

  let!(:chronicle) do
    c = FactoryBot.create(:chronicle, team: team, name: "Coastal Exploration")
    FactoryBot.create(:chronicle_entry, chronicle: c, team: team, entry: referenced_picture)
    c
  end

  let!(:memory) do
    FactoryBot.create(:memory, team: team, thought: referenced_thought, memo: "A calm evening reflection")
  end

  before do
    visit login_url
    fill_in :email, with: user.email
    fill_in :password, with: "foobar1234"
    click_button "Login"
    visit_switch_current_team(team)
  end

  it "allows destroying an unreferenced picture" do
    visit edit_current_team_picture_url(unreferenced_picture.urlsafe_id)

    expect(page).to have_button("Destroy this picture")
    find_button("Destroy this picture").click

    expect(page).to have_text("Are you sure you want to destroy this picture?")
    expect(page).to have_button("Destroy Insight")

    find_button("Destroy Insight", visible: :all).click

    expect(page).to have_text("Picture was successfully destroyed.")
    expect(Picture.find_by(id: unreferenced_picture.id)).to be_nil
  end

  it "blocks destroying a picture referenced by a chronicle and displays the link" do
    visit edit_current_team_picture_url(referenced_picture.urlsafe_id)

    find_button("Destroy this picture").click

    expect(page).to have_text("This picture cannot be destroyed because it is still referenced by other content:")
    expect(page).to have_text("Chronicles:")
    expect(page).to have_link("Coastal Exploration", href: current_team_chronicle_path(chronicle))
    expect(page).to have_css("button.yui-btn--danger[disabled]")

    # Clicking the link navigates to the chronicle show page
    click_link "Coastal Exploration"
    expect(page).to have_current_path(current_team_chronicle_path(chronicle))
  end

  it "blocks destroying a thought referenced by a memory and displays the link" do
    visit edit_current_team_thought_url(referenced_thought.urlsafe_id)

    find_button("Destroy this thought").click

    expect(page).to have_text("This thought cannot be destroyed because it is still referenced by other content:")
    expect(page).to have_text("Memories:")
    expect(page).to have_link("A calm evening reflection", href: current_team_memory_path(memory))
    expect(page).to have_css("button.yui-btn--danger[disabled]")

    click_link "A calm evening reflection"
    expect(page).to have_current_path(current_team_memory_path(memory))
  end
end
