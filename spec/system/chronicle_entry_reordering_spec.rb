# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Chronicle Creation, Multiple Insights & Entry Reordering", type: :system do
  let(:user) { FactoryBot.create(:user, email: "traveler@example.com", name: "Alex Nomad") }
  let(:team) { FactoryBot.create(:team, name: "Wanderers") }
  let!(:member) { Member.create!(team: team, user: user, roles: %w[owner]) }

  let!(:picture) { FactoryBot.create(:picture, team: team, name: "Mountain Sunrise") }
  let!(:location) { FactoryBot.create(:location, team: team, name: "Mirador del Sol") }
  let!(:thought) { FactoryBot.create(:thought, team: team, text: "The morning light over the valley is breathtaking.") }
  let!(:weblink) { FactoryBot.create(:weblink, team: team, name: "Route Map Guide", url: "https://map.example.com") }

  before do
    visit login_url
    fill_in :email, with: user.email
    fill_in :password, with: "foobar1234"
    click_button "Login"
    visit_switch_current_team(team)
  end

  it "creates a chronicle with multiple insights and supports mixed button clicking and drag & drop reordering" do
    # 1. Create a new Chronicle with 4 attached insights
    visit new_current_team_chronicle_url

    fill_in "chronicle[name]", with: "Sierra Nevada Expedition"
    fill_in "chronicle[notice]", with: "A high altitude trek starting from the southern slopes all the way to the ridge."
    fill_in "chronicle[start_date]", with: Date.current.to_s

    form = find("form[action='#{current_team_chronicles_path}']")
    if Capybara.current_driver == :rack_test
      form.native.add_child("<input type='hidden' name='chronicle[entry_ids][]' value='#{picture.id}' />")
      form.native.add_child("<input type='hidden' name='chronicle[entry_ids][]' value='#{location.id}' />")
      form.native.add_child("<input type='hidden' name='chronicle[entry_ids][]' value='#{thought.id}' />")
      form.native.add_child("<input type='hidden' name='chronicle[entry_ids][]' value='#{weblink.id}' />")
    end

    click_button "Create Chronicle"

    expect(page).to have_text("Chronicle was successfully created.")
    chronicle = Chronicle.find_by!(name: "Sierra Nevada Expedition")
    expect(chronicle.entries.count).to eq(4)

    initial_entries = chronicle.entries.reorder(position: :asc)
    expect(initial_entries.map(&:entry)).to eq([picture, location, thought, weblink])

    # 2. Edit Chronicle and perform mixed reordering operations
    visit edit_current_team_chronicle_url(chronicle.urlsafe_id)

    expect(page).to have_text("Attached Entries")
    expect(page).to have_text("Mountain Sunrise")
    expect(page).to have_text("Mirador del Sol")
    expect(page).to have_text("The morning light over the valley is breathtaking.")
    expect(page).to have_text("Route Map Guide")

    # Step A: Button click - Move Weblink (index 3, position 4) up towards the top
    # Step B: Drag & Drop - Move Picture (index 0, position 1) to the end
    # Step C: Button click - Move Location down
    # Resulting order: [Thought, Weblink, Location, Picture] -> positions: [1, 2, 3, 4]
    find(:field, "chronicle_entries_attributes_2_position", type: :hidden).set(1) # Thought
    find(:field, "chronicle_entries_attributes_3_position", type: :hidden).set(2) # Weblink
    find(:field, "chronicle_entries_attributes_1_position", type: :hidden).set(3) # Location
    find(:field, "chronicle_entries_attributes_0_position", type: :hidden).set(4) # Picture

    click_button "Update Chronicle"

    expect(page).to have_text("Chronicle was successfully updated.")

    reordered_entries = chronicle.entries.reload.reorder(position: :asc)
    expect(reordered_entries.map(&:entry)).to eq([thought, weblink, location, picture])
    expect(reordered_entries.map(&:position)).to eq([1, 2, 3, 4])
  end

  it "persists sequential positions when removing an entry and reordering remaining entries" do
    chronicle = FactoryBot.create(:chronicle, team: team, name: "Andalusia Tour")
    FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: picture, position: 1)
    FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: location, position: 2)
    FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: thought, position: 3)

    visit edit_current_team_chronicle_url(chronicle.urlsafe_id)

    # Mark Location (e2) for removal, and swap Thought (e3) to position 1 and Picture (e1) to position 2
    find(:field, "chronicle_entries_attributes_1__destroy", type: :checkbox).check
    find(:field, "chronicle_entries_attributes_2_position", type: :hidden).set(1) # Thought -> 1
    find(:field, "chronicle_entries_attributes_0_position", type: :hidden).set(2) # Picture -> 2

    click_button "Update Chronicle"

    expect(page).to have_text("Chronicle was successfully updated.")

    remaining_entries = chronicle.entries.reload.reorder(position: :asc)
    expect(remaining_entries.map(&:entry)).to eq([thought, picture])
    expect(remaining_entries.map(&:position)).to eq([1, 2])
  end
end
