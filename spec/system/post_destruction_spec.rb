# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Post Destruction with Orphaned Insights Option", type: :system do
  let(:user) { FactoryBot.create(:user, email: "creator@example.com", name: "Sam Creator") }
  let(:team) { FactoryBot.create(:team, name: "Creators Team") }
  let!(:member) { Member.create!(team: team, user: user, roles: %w[owner]) }

  let!(:unshared_picture) { FactoryBot.create(:picture, team: team, name: "Lone Mountain") }
  let!(:shared_location) { FactoryBot.create(:location, team: team, name: "City Plaza") }

  let!(:chronicle) do
    c = FactoryBot.create(:chronicle, team: team, name: "Desert Journey")
    FactoryBot.create(:chronicle_entry, chronicle: c, team: team, entry: unshared_picture)
    FactoryBot.create(:chronicle_entry, chronicle: c, team: team, entry: shared_location)
    c
  end

  let!(:memory) do
    FactoryBot.create(:memory, team: team, location: shared_location, memo: "Remembering City Plaza")
  end

  before do
    visit login_url
    fill_in :email, with: user.email
    fill_in :password, with: "foobar1234"
    click_button "Login"
    visit_switch_current_team(team)
  end

  it "destroys chronicle and only unshared insights when user confirms deleting orphaned insights" do
    visit edit_current_team_chronicle_url(chronicle.urlsafe_id)

    expect(page).to have_button("Destroy this chronicle")
    expect(page).to have_button("Destroy & Delete Orphaned Insights", visible: :all)

    # Click Destroy & Delete Orphaned Insights
    find_button("Destroy & Delete Orphaned Insights", visible: :all).click

    expect(page).to have_text("Chronicle was successfully destroyed.")
    expect(Chronicle.find_by(id: chronicle.id)).to be_nil
    expect(Picture.find_by(id: unshared_picture.id)).to be_nil
    expect(Location.find_by(id: shared_location.id)).to eq(shared_location)
  end

  it "destroys memory only when user selects Destroy Memory Only" do
    unshared_thought = FactoryBot.create(:thought, team: team, text: "Private thought")
    standalone_memory = FactoryBot.create(:memory, team: team, thought: unshared_thought, memo: "A standalone memory")

    visit edit_current_team_memory_url(standalone_memory.urlsafe_id)

    find_button("Destroy Memory Only", visible: :all).click

    expect(page).to have_text("Memory was successfully destroyed.")
    expect(Memory.find_by(id: standalone_memory.id)).to be_nil
    expect(Thought.find_by(id: unshared_thought.id)).to eq(unshared_thought)
  end
end
