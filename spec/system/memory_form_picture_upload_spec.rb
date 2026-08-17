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

  it "creates a memory by directly uploading a new picture in the form (regression test)" do
    visit new_current_team_memory_url

    fill_in "memory[memo]", with: "Camping under the stars on the edge of the canyon."
    find("summary", text: "Or Upload New Picture").click
    attach_file "memory[picture_file]", test_image_path
    fill_in "memory[picture_name]", with: "Canyon Milky Way"
    click_button "Create Memory"

    expect(page).to have_text("Memory was successfully created.")
    expect(page).to have_text("Camping under the stars on the edge of the canyon.")
    expect(page).to have_text("Canyon Milky Way")

    memory = Memory.last
    expect(memory.picture).to be_present
    expect(memory.picture.name).to eq("Canyon Milky Way")
    expect(memory.picture.file).to be_attached
  end

  it "updates a memory by uploading a replacement picture in the edit form (regression test)" do
    memory = Memory.create!(
      team: team,
      memo: "Initial memory memo text before update",
      visibility: "published"
    )

    visit edit_current_team_memory_url(memory)

    fill_in "memory[memo]", with: "Updated memory with exciting new photo!"
    find("summary", text: "Or Upload New Picture").click
    attach_file "memory[picture_file]", test_image_path
    fill_in "memory[picture_name]", with: "Replacement Photo"
    click_button "Update Memory"

    expect(page).to have_text("Memory was successfully updated.")
    expect(page).to have_text("Updated memory with exciting new photo!")
    expect(page).to have_text("Replacement Photo")

    memory.reload
    expect(memory.picture).to be_present
    expect(memory.picture.name).to eq("Replacement Photo")
  end

  it "creates a memory with attached location, thought, and weblink (regression test)" do
    existing_location = FactoryBot.create(:location, team: team, name: "Ordesa Valley")

    visit new_current_team_memory_url

    fill_in "memory[memo]", with: "Hiking high in the Pyrenees with majestic mountain peaks."
    select "Ordesa Valley", from: "memory[location_id]"
    find("summary", text: "Or Create New Thought").click
    fill_in "memory[thought_text]", with: "Never felt so peaceful and connected to nature."
    find("summary", text: "Or Create New Weblink").click
    fill_in "memory[weblink_name]", with: "Park Trail Guide"
    fill_in "memory[weblink_url]", with: "https://ordesa-national-park.es"
    click_button "Create Memory"

    expect(page).to have_text("Memory was successfully created.")
    expect(page).to have_text("Ordesa Valley")
    expect(page).to have_text("Never felt so peaceful and connected to nature.")
    expect(page).to have_text("Park Trail Guide")

    memory = Memory.last
    expect(memory.location).to eq(existing_location)
    expect(memory.thought.text).to eq("Never felt so peaceful and connected to nature.")
    expect(memory.weblink.name).to eq("Park Trail Guide")
  end

  it "detaches attached insights when choosing None (regression test)" do
    picture = FactoryBot.create(:picture, team: team, name: "Detachable Pic")
    location = FactoryBot.create(:location, team: team, name: "Detachable Loc")
    thought = FactoryBot.create(:thought, team: team, text: "Detachable Thought")
    weblink = FactoryBot.create(:weblink, team: team, name: "Detachable Link")

    memory = Memory.create!(
      team: team,
      memo: "Memory with all insights to detach",
      picture: picture,
      location: location,
      thought: thought,
      weblink: weblink,
      visibility: "published"
    )

    visit edit_current_team_memory_url(memory)

    find(:field, "memory_picture_id", type: :hidden).set("")
    select "None (no location)", from: "memory[location_id]"
    select "None (no thought)", from: "memory[thought_id]"
    select "None (no weblink)", from: "memory[weblink_id]"
    click_button "Update Memory"

    expect(page).to have_text("Memory was successfully updated.")
    memory.reload
    expect(memory.picture).to be_nil
    expect(memory.location).to be_nil
    expect(memory.thought).to be_nil
    expect(memory.weblink).to be_nil
  end

  it "creates a memory with an inline created location selecting country code" do
    visit new_current_team_memory_url

    fill_in "memory[memo]", with: "Exploring ancient ruins"
    find("summary", text: "Or Create New Location").click
    fill_in "memory[location_name]", with: "Acropolis of Athens"
    select "Greece 🇬🇷 [GR] Ελλάδα", from: "memory[location_country_code]"
    fill_in "memory[location_address]", with: "Athens 105 58, Greece"
    click_button "Create Memory"

    expect(page).to have_text("Memory was successfully created.")
    expect(page).to have_text("Exploring ancient ruins")
    expect(page).to have_text("Acropolis of Athens")

    memory = Memory.last
    expect(memory.location).to be_present
    expect(memory.location.name).to eq("Acropolis of Athens")
    expect(memory.location.country_code).to be_present
  end

  it "renders validation errors cleanly and retains all form fields when creation fails" do
    FactoryBot.create(:location, team: team, name: "Acropolis of Athens")

    visit new_current_team_memory_url

    fill_in "memory[memo]", with: "Exploring ancient ruins"
    find("summary", text: "Or Upload New Picture").click
    attach_file "memory[picture_file]", Rails.root.join("spec/support/macbookair_stickered.jpg")
    fill_in "memory[picture_name]", with: "Ruins Photo"
    find("summary", text: "Or Create New Location").click
    fill_in "memory[location_name]", with: "Acropolis of Athens"
    select "Greece 🇬🇷 [GR] Ελλάδα", from: "memory[location_country_code]"
    fill_in "memory[location_address]", with: "Athens Center"
    find("summary", text: "Or Create New Thought").click
    fill_in "memory[thought_text]", with: "History is alive here."
    find("summary", text: "Or Create New Weblink").click
    fill_in "memory[weblink_name]", with: "Athens Guide"
    fill_in "memory[weblink_url]", with: "https://athens-guide.example.com"
    fill_in "memory[weblink_description]", with: "Comprehensive travel tips"
    click_button "Create Memory"

    expect(page).to have_text("Location")
    expect(page).to have_current_path(current_team_memories_path)
    expect(find_field("memory[memo]").value).to eq("Exploring ancient ruins")
    expect(find_field("memory[location_name]").value).to eq("Acropolis of Athens")
    expect(find_field("memory[location_address]").value).to eq("Athens Center")
    expect(find_field("memory[picture_name]").value).to eq("Ruins Photo")
    expect(find_field("memory[thought_text]").value).to eq("History is alive here.")
    expect(find_field("memory[weblink_name]").value).to eq("Athens Guide")
    expect(find_field("memory[weblink_url]").value).to eq("https://athens-guide.example.com")
    expect(find_field("memory[weblink_description]").value).to eq("Comprehensive travel tips")
    expect(page).to have_select("memory[location_country_code]", selected: "Greece 🇬🇷 [GR] Ελλάδα")
  end
end
