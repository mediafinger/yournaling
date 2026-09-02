# frozen_string_literal: true

require "rails_helper"

RSpec.describe InsightsDropdownComponent, type: :component do
  it "renders manage mode insights links" do
    rendered = render_inline(described_class.new(scope: :current_team))

    expect(rendered.to_html).to have_css("details.yui-menu summary", text: "Insights")
    expect(rendered.to_html).to have_link("Pictures", href: "/current_team/pictures", visible: :all)
    expect(rendered.to_html).to have_link("Thoughts", href: "/current_team/thoughts", visible: :all)
    expect(rendered.to_html).to have_link("Locations", href: "/current_team/locations", visible: :all)
    expect(rendered.to_html).to have_link("Weblinks", href: "/current_team/weblinks", visible: :all)
  end

  it "renders admin mode insights links" do
    rendered = render_inline(described_class.new(scope: :admin))

    expect(rendered.to_html).to have_css("details.yui-menu summary", text: "Insights")
    expect(rendered.to_html).to have_link("Pictures", href: "/admin/pictures", visible: :all)
    expect(rendered.to_html).to have_link("Locations", href: "/admin/locations", visible: :all)
    expect(rendered.to_html).to have_link("Thoughts", href: "/admin/thoughts", visible: :all)
    expect(rendered.to_html).to have_link("Weblinks", href: "/admin/weblinks", visible: :all)
  end

  context "when an insight path is active" do
    before do
      allow_any_instance_of(ApplicationComponent).to receive(:active_path?).and_return(false) # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(ApplicationComponent).to receive(:active_path?).with("/current_team/pictures").and_return(true) # rubocop:disable RSpec/AnyInstance
    end

    it "marks the trigger strong and the active item with aria-current" do
      rendered = render_inline(described_class.new(scope: :current_team))

      expect(rendered).to have_css("summary.yui-nav-item--strong", text: "Insights")
      expect(rendered).to have_css("a[href='/current_team/pictures'][aria-current='page']", visible: :all)
    end
  end

  context "when no insight path is active" do
    before do
      allow_any_instance_of(ApplicationComponent).to receive(:active_path?).and_return(false) # rubocop:disable RSpec/AnyInstance
    end

    it "leaves the trigger un-emphasised" do
      rendered = render_inline(described_class.new(scope: :current_team))

      expect(rendered).to have_no_css("summary.yui-nav-item--strong")
      expect(rendered).to have_css("summary.yui-nav-item", text: "Insights")
    end
  end
end
