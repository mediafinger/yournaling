# frozen_string_literal: true

require "rails_helper"

RSpec.describe Yui::NavbarComponent, type: :component do
  it "renders a <nav> with one <ul> per group" do
    rendered = render_inline(described_class.new) do |bar|
      bar.with_group { "<li>a</li>".html_safe }
      bar.with_group { "<li>b</li>".html_safe }
    end

    expect(rendered).to have_css("nav.ex-navbar > .ex-navbar__inner > ul.ex-navbar__group", count: 2)
  end

  it "sets aria-label and data-area" do
    rendered = render_inline(described_class.new(area: "team", label: "Workspace")) { |b| b.with_group { "x" } }

    expect(rendered).to have_css("nav.ex-navbar[aria-label='Workspace'][data-area='team']")
  end

  it "omits data-area when no area is given" do
    rendered = render_inline(described_class.new) { |b| b.with_group { "x" } }

    expect(rendered.css("nav").first[:"data-area"]).to be_nil
  end
end
