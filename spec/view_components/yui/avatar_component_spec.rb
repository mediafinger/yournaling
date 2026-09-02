# frozen_string_literal: true

require "rails_helper"

RSpec.describe Yui::AvatarComponent, type: :component do
  it "derives initials from the name and hides them from assistive tech" do
    rendered = render_inline(described_class.new(name: "Andreas Finger"))

    expect(rendered).to have_css("span.yui-avatar[title='Andreas Finger']")
    expect(rendered).to have_css("span[aria-hidden='true']", text: "AF")
  end

  it "uses a single initial for a one-word name" do
    rendered = render_inline(described_class.new(name: "Mira"))

    expect(rendered).to have_css("span[aria-hidden='true']", text: "M")
  end

  it "renders an <img> with alt text when a src is given" do
    rendered = render_inline(described_class.new(name: "Mira Kessler", src: "/uploads/mira.jpg"))

    expect(rendered).to have_css("img[alt='Mira Kessler'][loading='lazy']")
  end

  it "maps size to a modifier class" do
    rendered = render_inline(described_class.new(name: "X Y", size: :lg))

    expect(rendered).to have_css(".yui-avatar.yui-avatar--lg")
  end
end
