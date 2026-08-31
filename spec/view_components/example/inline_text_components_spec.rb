# frozen_string_literal: true

require "rails_helper"

# The small single-element inline primitives.
RSpec.describe "Example inline text primitives", type: :component do # rubocop:disable RSpec/DescribeClass
  describe Example::EyebrowComponent do
    it "renders an uppercase kicker paragraph" do
      rendered = render_inline(described_class.new("Chronicle"))
      expect(rendered).to have_css("p.ex-eyebrow", text: "Chronicle")
    end

    it "accepts block content" do
      rendered = render_inline(described_class.new) { "Since 2019" }
      expect(rendered).to have_css("p.ex-eyebrow", text: "Since 2019")
    end
  end

  describe Example::EmphasisComponent do
    it "renders semantic <strong>" do
      rendered = render_inline(described_class.new("real weight"))
      expect(rendered).to have_css("strong.ex-strong", text: "real weight")
    end
  end

  describe Example::QuoteComponent do
    it "renders semantic <em>" do
      rendered = render_inline(described_class.new("a little more quietly"))
      expect(rendered).to have_css("em.ex-quote", text: "a little more quietly")
    end
  end

  describe Example::DividerComponent do
    it "renders an <hr> with no label" do
      rendered = render_inline(described_class.new)
      expect(rendered).to have_css("hr.ex-divider")
    end

    it "renders a labelled separator" do
      rendered = render_inline(described_class.new("Later that year"))
      expect(rendered).to have_css(".ex-divider--labeled[role='separator']", text: "Later that year")
      expect(rendered).to have_no_css("hr")
    end
  end

  describe Example::ProseComponent do
    it "wraps block content in .ex-prose" do
      rendered = render_inline(described_class.new) { "<p>Body</p>".html_safe }
      expect(rendered).to have_css("div.ex-prose p", text: "Body")
    end
  end
end
