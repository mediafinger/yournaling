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

  it "detaches an attached picture when choosing None (regression test)" do
    picture = FactoryBot.create(:picture, team: team, name: "Detachable Pic")
    memory = Memory.create!(
      team: team,
      memo: "Memory with a photo to detach",
      picture: picture,
      visibility: "published"
    )

    visit edit_current_team_memory_url(memory)

    find(:field, "memory_picture_id", type: :hidden).set("")
    click_button "Update Memory"

    expect(page).to have_text("Memory was successfully updated.")
    memory.reload
    expect(memory.picture).to be_nil
  end
end
