# frozen_string_literal: true

require "rails_helper"

RSpec.describe Yui::TabsComponent, type: :component do
  def render_tabs(active: 0)
    render_inline(described_class.new(label: "Location", active:)) do |t|
      t.with_panel(title: "Address") { "Address fields".html_safe }
      t.with_panel(title: "GPS") { "GPS fields".html_safe }
    end
  end

  it "renders a tablist wired to the yui-tabs controller" do
    rendered = render_tabs

    expect(rendered).to have_css(".yui-tabs[data-controller='yui-tabs']")
    expect(rendered).to have_css("[role='tablist'][aria-label='Location']")
    expect(rendered).to have_css("button[role='tab'][data-yui-tabs-target='tab']", count: 2)
    expect(rendered).to have_css("button[role='tab']", text: "Address")
    expect(rendered).to have_css("button[role='tab']", text: "GPS")
  end

  it "marks the active tab selected and hides the other panel" do
    rendered = render_tabs(active: 1)

    tabs = rendered.css("button[role='tab']")
    expect(tabs[0][:"aria-selected"]).to eq("false")
    expect(tabs[1][:"aria-selected"]).to eq("true")

    panels = rendered.css("[role='tabpanel']")
    expect(panels[0].key?("hidden")).to be(true)
    expect(panels[1].key?("hidden")).to be(false)
  end

  it "links each tab to its panel via aria-controls / aria-labelledby" do
    rendered = render_tabs

    tab = rendered.css("button[role='tab']").first
    panel = rendered.css("[role='tabpanel']").first
    expect(tab[:"aria-controls"]).to eq(panel[:id])
    expect(panel[:"aria-labelledby"]).to eq(tab[:id])
  end
end
