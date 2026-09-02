# frozen_string_literal: true

require "rails_helper"

RSpec.describe Yui::TagComponent, type: :component do
  it "renders a span by default" do
    rendered = render_inline(described_class.new("beach"))

    expect(rendered).to have_css("span.yui-tag", text: "beach")
  end

  it "renders an anchor when given an href" do
    rendered = render_inline(described_class.new("lisbon", href: "/locations/lisbon"))

    expect(rendered).to have_link("lisbon", href: "/locations/lisbon", class: "yui-tag")
  end

  it "renders a leading decorative icon" do
    rendered = render_inline(described_class.new("Ericeira", icon: "map-pin"))

    expect(rendered).to have_css("span.yui-tag svg.yui-icon[aria-hidden='true']")
  end

  describe "removable" do
    let(:rendered) { render_inline(described_class.new("winter", removable: true)) }

    it "renders a labelled remove button" do
      expect(rendered).to have_css("button.yui-tag__remove[aria-label='Remove winter']")
    end
  end
end
