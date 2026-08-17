# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Memory Form Picture Upload & Insight Management", type: :system do
  let(:user) { FactoryBot.create(:user, email: "creator@example.com", name: "Sam Nomad") }
  let(:team) { FactoryBot.create(:team, name: "Sunset Voyagers") }
  let!(:member) { Member.create!(team: team, user: user, roles: %w[owner]) }
  let(:test_image_path) { Rails.root.join("spec/support/macbookair_stickered.jpg") }

  before do
    visit login_url
    fill_in :email, with: user.email
    fill_in :password, with: "foobar1234"
    click_button "Login"
    visit_switch_current_team(team)
  end

  it "creates a memory with an attached picture and location" do
    picture = FactoryBot.create(:picture, team: team, name: "Sunset Beach Photo")
    location = FactoryBot.create(:location, team: team, name: "Cabo de Gata Park")

    visit new_current_team_memory_url

    fill_in "memory[memo]", with: "Camping under the stars on the edge of the canyon."
    find(:field, "memory_picture_id", type: :hidden).set(picture.id)
    find(:field, "memory_location_id", type: :hidden).set(location.id)
    click_button "Create Memory"

    expect(page).to have_text("Memory was successfully created.")
    expect(page).to have_text("Camping under the stars on the edge of the canyon.")
    expect(page).to have_text("Sunset Beach Photo")
    expect(page).to have_text("Cabo de Gata Park")

    memory = Memory.last
    expect(memory.picture).to eq(picture)
    expect(memory.location).to eq(location)
  end

  it "creates a memory with attached location, thought, and weblink" do
    location = FactoryBot.create(:location, team: team, name: "Ordesa National Park")
    thought = FactoryBot.create(:thought, team: team, text: "Never felt so peaceful and connected to nature.")
    weblink = FactoryBot.create(:weblink, team: team, name: "Pyrenees Trail Guide")

    visit new_current_team_memory_url

    fill_in "memory[memo]", with: "Hiking high in the Pyrenees with majestic mountain peaks."
    find(:field, "memory_location_id", type: :hidden).set(location.id)
    find(:field, "memory_thought_id", type: :hidden).set(thought.id)
    find(:field, "memory_weblink_id", type: :hidden).set(weblink.id)
    click_button "Create Memory"

    expect(page).to have_text("Memory was successfully created.")
    expect(page).to have_text("Ordesa National Park")
    expect(page).to have_text("Never felt so peaceful and connected to nature.")
    expect(page).to have_text("Pyrenees Trail Guide")

    memory = Memory.last
    expect(memory.location).to eq(location)
    expect(memory.thought).to eq(thought)
    expect(memory.weblink).to eq(weblink)
  end

  it "updates a memory by replacing and clearing attached insights" do
    picture = FactoryBot.create(:picture, team: team, name: "Old Pic")
    location = FactoryBot.create(:location, team: team, name: "Old Loc")
    new_picture = FactoryBot.create(:picture, team: team, name: "New Pic")

    memory = Memory.create!(
      team: team,
      memo: "Initial memory before update",
      picture: picture,
      location: location,
      visibility: "published"
    )

    visit edit_current_team_memory_url(memory)

    fill_in "memory[memo]", with: "Updated memory with replaced insights"
    find(:field, "memory_picture_id", type: :hidden).set(new_picture.id)
    find(:field, "memory_location_id", type: :hidden).set("")
    click_button "Update Memory"

    expect(page).to have_text("Memory was successfully updated.")
    expect(page).to have_text("Updated memory with replaced insights")
    expect(page).to have_text("New Pic")

    memory.reload
    expect(memory.picture).to eq(new_picture)
    expect(memory.location).to be_nil
  end

  it "renders validation errors cleanly and retains entered memo when creation fails" do
    visit new_current_team_memory_url

    fill_in "memory[memo]", with: "A" # Fails minimum length validation
    click_button "Create Memory"

    expect(page).to have_text("Memo is too short")
    expect(find_field("memory[memo]").value).to eq("A")
  end
end
