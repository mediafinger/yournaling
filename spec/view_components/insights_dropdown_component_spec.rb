# frozen_string_literal: true

require "rails_helper"

RSpec.describe InsightsDropdownComponent, type: :component do
  it "renders manage mode insights links" do
    rendered = render_inline(described_class.new(scope: :current_team))

    expect(rendered.to_html).to have_css("details.dropdown summary", text: "Insights")
    expect(rendered.to_html).to have_link("Pictures", href: "/current_team/pictures", visible: :all)
    expect(rendered.to_html).to have_link("Thoughts", href: "/current_team/thoughts", visible: :all)
    expect(rendered.to_html).to have_link("Locations", href: "/current_team/locations", visible: :all)
    expect(rendered.to_html).to have_link("Weblinks", href: "/current_team/weblinks", visible: :all)
  end

  it "renders admin mode insights links" do
    rendered = render_inline(described_class.new(scope: :admin))

    expect(rendered.to_html).to have_css("details.dropdown summary", text: "Insights")
    expect(rendered.to_html).to have_link("Pictures", href: "/admin/pictures", visible: :all)
    expect(rendered.to_html).to have_link("Locations", href: "/admin/locations", visible: :all)
    expect(rendered.to_html).to have_link("Thoughts", href: "/admin/thoughts", visible: :all)
    expect(rendered.to_html).to have_link("Weblinks", href: "/admin/weblinks", visible: :all)
  end

  context "when an insight path is active in manage mode" do
    before do
      allow_any_instance_of(ApplicationComponent).to receive(:active_path?).with("/current_team/pictures").and_return(true) # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(ApplicationComponent).to receive(:active_path?).with(any_args).and_return(false) # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(ApplicationComponent).to receive(:active_path?).with("/current_team/pictures").and_return(true) # rubocop:disable RSpec/AnyInstance
    end

    it "highlights the dropdown summary with role=button and highlights the active link" do
      rendered = render_inline(described_class.new(scope: :current_team))

      expect(rendered.to_html).to have_css("details.dropdown summary[role='button']", text: "Insights")
      expect(rendered.to_html).to have_css("a[href='/current_team/pictures'][role='button']", visible: :all)
    end
  end

  context "when no insight path is active" do
    before do
      allow_any_instance_of(ApplicationComponent).to receive(:active_path?).and_return(false) # rubocop:disable RSpec/AnyInstance
    end

    it "renders the dropdown summary without role=button" do
      rendered = render_inline(described_class.new(scope: :current_team))

      expect(rendered.to_html).to have_no_css("details.dropdown summary[role='button']")
    end
  end
end
