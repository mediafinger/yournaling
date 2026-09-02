# frozen_string_literal: true

require "rails_helper"

RSpec.describe MarkdownRenderer do
  describe ".render" do
    it "returns a blank safe buffer for nil / blank input" do
      expect(described_class.render(nil)).to eq("")
      expect(described_class.render("")).to be_html_safe
    end

    it "renders basic Markdown" do
      html = described_class.render("# Title\n\nA **bold** word.")
      expect(html).to include("<h1")
      expect(html).to include("<strong>bold</strong>")
    end

    it "renders GFM tables" do
      html = described_class.render("| a | b |\n|---|---|\n| 1 | 2 |")
      expect(html).to include("<table>").and include("<td>1</td>")
    end

    it "renders GFM strikethrough, task lists and autolinks" do
      expect(described_class.render("~~gone~~")).to include("<del>gone</del>")
      expect(described_class.render("- [x] done")).to include("<input")
      expect(described_class.render("see https://example.com here")).to include('href="https://example.com"')
    end

    it "drops raw HTML (no executable script tag survives)" do
      html = described_class.render("Hello <script>alert(1)</script> world")
      expect(html).not_to include("<script")
    end

    it "neutralises javascript: links" do
      html = described_class.render("[click](javascript:alert(1))")
      expect(html).not_to include("javascript:")
    end

    it "strips event-handler attributes and iframes even if smuggled in" do
      html = described_class.render("<iframe src=\"evil\"></iframe>\n\n<img src=x onerror=alert(1)>")
      expect(html).not_to include("<iframe")
      expect(html).not_to include("onerror")
    end

    it "returns an html_safe buffer" do
      expect(described_class.render("plain")).to be_html_safe
    end
  end
end
