# frozen_string_literal: true

require "rails_helper"

RSpec.describe Yui::NavItemComponent, type: :component do
  it "renders an <li> wrapping a link" do
    rendered = render_inline(described_class.new("Search", href: "/search"))

    expect(rendered).to have_css("li.yui-navbar__item > a.yui-nav-item[href='/search']", text: "Search")
  end

  it "marks the current page with aria-current and the active class" do
    rendered = render_inline(described_class.new("Memories", href: "/m", active: true))

    expect(rendered).to have_css("a.yui-nav-item--active.yui-nav-item--strong[aria-current='page']")
  end

  it "gives the cta variant the strong treatment without aria-current" do
    rendered = render_inline(described_class.new("+ New", href: "/new", variant: :cta))

    link = rendered.css("a").first
    expect(link[:class]).to include("yui-nav-item--strong")
    expect(link[:class]).not_to include("yui-nav-item--active")
    expect(link[:"aria-current"]).to be_nil
  end

  it "passes through data attributes (e.g. turbo-method)" do
    rendered = render_inline(described_class.new("Logout", href: "/logout", data: { turbo_method: :delete }))

    expect(rendered).to have_css("a[data-turbo-method='delete']")
  end
end
