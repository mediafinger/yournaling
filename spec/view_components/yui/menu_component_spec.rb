# frozen_string_literal: true

require "rails_helper"

RSpec.describe Yui::MenuComponent, type: :component do
  it "renders a <details> menu with a summary trigger and a role=menu panel" do
    rendered = render_inline(described_class.new("+ New", trigger_class: "yui-nav-item")) { "items".html_safe }

    expect(rendered).to have_css("details.yui-menu[data-controller='yui-menu']")
    expect(rendered).to have_css("summary.yui-menu__trigger.yui-nav-item[data-yui-menu-target='trigger']", text: "+ New")
    expect(rendered).to have_css(".yui-menu__panel[role='menu'][data-action='click->yui-menu#choose']", text: "items",
      visible: :all)
  end

  it "right-aligns the panel for align: :end" do
    rendered = render_inline(described_class.new("x", align: :end)) { "y" }

    expect(rendered).to have_css("details.yui-menu.yui-menu--end")
  end

  describe Yui::MenuItemComponent do
    it "renders a link menuitem by default" do
      rendered = render_inline(described_class.new("Memory", href: "/m"))
      expect(rendered).to have_css("a.yui-menu__item[role='menuitem'][href='/m']", text: "Memory")
    end

    it "renders a button menuitem for as: :button" do
      rendered = render_inline(described_class.new("Do it", as: :button))
      expect(rendered).to have_css("button.yui-menu__item[type='button'][role='menuitem']")
    end

    it "marks the active item" do
      rendered = render_inline(described_class.new("Pictures", href: "/p", active: true))
      expect(rendered).to have_css("a.yui-menu__item--active[aria-current='page']")
    end
  end
end
