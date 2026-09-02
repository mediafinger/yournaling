# frozen_string_literal: true

require "rails_helper"

# The small single-element inline primitives.
RSpec.describe "Yui inline text primitives", type: :component do # rubocop:disable RSpec/DescribeClass
  describe Yui::EyebrowComponent do
    it "renders an uppercase kicker paragraph" do
      rendered = render_inline(described_class.new("Chronicle"))
      expect(rendered).to have_css("p.yui-eyebrow", text: "Chronicle")
    end

    it "accepts block content" do
      rendered = render_inline(described_class.new) { "Since 2019" }
      expect(rendered).to have_css("p.yui-eyebrow", text: "Since 2019")
    end
  end

  describe Yui::EmphasisComponent do
    it "renders semantic <strong>" do
      rendered = render_inline(described_class.new("real weight"))
      expect(rendered).to have_css("strong.yui-strong", text: "real weight")
    end
  end

  describe Yui::QuoteComponent do
    it "renders semantic <em>" do
      rendered = render_inline(described_class.new("a little more quietly"))
      expect(rendered).to have_css("em.yui-quote", text: "a little more quietly")
    end
  end

  describe Yui::DividerComponent do
    it "renders an <hr> with no label" do
      rendered = render_inline(described_class.new)
      expect(rendered).to have_css("hr.yui-divider")
    end

    it "renders a labelled separator" do
      rendered = render_inline(described_class.new("Later that year"))
      expect(rendered).to have_css(".yui-divider--labeled[role='separator']", text: "Later that year")
      expect(rendered).to have_no_css("hr")
    end
  end

  describe Yui::ProseComponent do
    it "wraps block content in .yui-prose" do
      rendered = render_inline(described_class.new) { "<p>Body</p>".html_safe }
      expect(rendered).to have_css("div.yui-prose p", text: "Body")
    end
  end
end
