# frozen_string_literal: true

require "rails_helper"

RSpec.describe InsightAttachmentManagerComponent, type: :component do
  let(:team) { FactoryBot.create(:team) }
  let(:memory) { FactoryBot.create(:memory, team: team) }
  let!(:picture) { FactoryBot.create(:picture, team: team, name: "Sunset View") }
  let!(:location) { FactoryBot.create(:location, team: team, name: "Cabo de Gata") }
  let!(:thought) { FactoryBot.create(:thought, team: team, text: "A deep thought") }
  let!(:weblink) { FactoryBot.create(:weblink, team: team, name: "Travel Blog") }

  it "renders attached insight chips and remove buttons for attached insights" do
    memory.picture = picture
    memory.location = location
    memory.thought = thought
    memory.weblink = weblink

    view_context = ActionController::Base.new.view_context
    form = ActionView::Helpers::FormBuilder.new(:memory, memory, view_context, {})

    rendered = render_inline(described_class.new(form: form, scope: "current_team", mode: :single))

    expect(rendered.to_html).to include("📍 Location:")
    expect(rendered.to_html).to include("Cabo de Gata")
    expect(rendered.to_html).to include("🖼 Picture:")
    expect(rendered.to_html).to include("Sunset View")
    expect(rendered.to_html).to include("💭 Thought:")
    expect(rendered.to_html).to include("A deep thought")
    expect(rendered.to_html).to include("🔗 Weblink:")
    expect(rendered.to_html).to include("Travel Blog")
  end

  it "renders Add Insight menu and templates for in-flow creation" do
    view_context = ActionController::Base.new.view_context
    form = ActionView::Helpers::FormBuilder.new(:memory, memory, view_context, {})

    rendered = render_inline(described_class.new(form: form, scope: "current_team", mode: :single))

    expect(rendered.to_html).to include("+ Add Insight")
    expect(rendered.to_html).to include('data-insight-manager-target="locationTemplate"')
    expect(rendered.to_html).to include('data-insight-manager-target="pictureTemplate"')
    expect(rendered.to_html).to include('data-insight-manager-target="thoughtTemplate"')
    expect(rendered.to_html).to include('data-insight-manager-target="weblinkTemplate"')
  end

  it "renders templates for existing insight selection" do
    view_context = ActionController::Base.new.view_context
    form = ActionView::Helpers::FormBuilder.new(:memory, memory, view_context, {})

    rendered = render_inline(described_class.new(form: form, scope: "current_team", mode: :single))

    expect(rendered.to_html).to include('data-insight-manager-target="existingLocationTemplate"')
    expect(rendered.to_html).to include('data-insight-manager-target="existingPictureTemplate"')
    expect(rendered.to_html).to include('data-insight-manager-target="existingThoughtTemplate"')
    expect(rendered.to_html).to include('data-insight-manager-target="existingWeblinkTemplate"')
  end

  it "offers a Story with a Marksmith editor in multiple mode (Chronicle)" do
    chronicle = FactoryBot.create(:chronicle, team: team)
    FactoryBot.create(:story, team: team, name: "Existing Chapter")
    view_context = ActionController::Base.new.view_context
    form = ActionView::Helpers::FormBuilder.new(:chronicle, chronicle, view_context, {})

    rendered = render_inline(described_class.new(form: form, scope: "current_team", mode: :multiple))

    expect(rendered.to_html).to include("+ Create New Story")
    expect(rendered.to_html).to include('data-insight-manager-target="storyTemplate"')
    expect(rendered.to_html).to include('data-insight-manager-target="existingStoryTemplate"')
    expect(rendered.to_html).to include('data-controller="marksmith list-continuation"')
    expect(rendered.to_html).to include("Existing Chapter")
  end

  it "hides the Story option in single mode (Memory)" do
    view_context = ActionController::Base.new.view_context
    form = ActionView::Helpers::FormBuilder.new(:memory, memory, view_context, {})

    rendered = render_inline(described_class.new(form: form, scope: "current_team", mode: :single))

    expect(rendered.to_html).not_to include("+ Create New Story")
  end

  it "renders location creation template with tabs for address, coordinates, and URL" do
    view_context = ActionController::Base.new.view_context
    form = ActionView::Helpers::FormBuilder.new(:memory, memory, view_context, {})

    rendered = render_inline(described_class.new(form: form, scope: "current_team", mode: :single))

    expect(rendered.to_html).to include("Location Details (Choose one)")
    expect(rendered.to_html).to include("Address")
    expect(rendered.to_html).to include("GPS Coordinates")
    expect(rendered.to_html).to include("Map / Web URL")
    expect(rendered.to_html).to include('name="location[country_code]"')
    expect(rendered.to_html).to include("Germany")
    expect(rendered.to_html).to include("Spain")
  end

  it "renders existing options populated with team records in select templates" do
    view_context = ActionController::Base.new.view_context
    form = ActionView::Helpers::FormBuilder.new(:memory, memory, view_context, {})

    rendered = render_inline(described_class.new(form: form, scope: "current_team", mode: :single))

    expect(rendered.to_html).to include("Sunset View")
    expect(rendered.to_html).to include("Cabo de Gata")
    expect(rendered.to_html).to include("A deep thought")
    expect(rendered.to_html).to include("Travel Blog")
  end

  it "renders date input fields without pre-filled default dates in templates" do
    view_context = ActionController::Base.new.view_context
    form = ActionView::Helpers::FormBuilder.new(:memory, memory, view_context, {})

    rendered = render_inline(described_class.new(form: form, scope: "current_team", mode: :single))

    expect(rendered.to_html).to include('id="drawer_location_date" name="location[date]"')
    expect(rendered.to_html).to include('id="drawer_picture_date" name="picture[date]"')
    expect(rendered.to_html).to include('id="drawer_thought_date" name="thought[date]"')
    expect(rendered.to_html).to include('id="drawer_weblink_date" name="weblink[date]"')
    expect(rendered.to_html).not_to include('id="drawer_picture_date" name="picture[date]" value=')
    expect(rendered.to_html).not_to include('id="drawer_thought_date" name="thought[date]" value=')
  end

  it "renders Add action button labels in templates instead of Attach" do
    view_context = ActionController::Base.new.view_context
    form = ActionView::Helpers::FormBuilder.new(:memory, memory, view_context, {})

    rendered = render_inline(described_class.new(form: form, scope: "current_team", mode: :single))

    expect(rendered.to_html).to include("Add Location")
    expect(rendered.to_html).to include("Add Picture")
    expect(rendered.to_html).to include("Add Thought")
    expect(rendered.to_html).to include("Add Weblink")
    expect(rendered.to_html).not_to include("Attach Location")
  end
end
