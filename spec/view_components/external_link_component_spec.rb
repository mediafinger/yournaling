# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExternalLinkComponent, type: :component do
  it "renders an external link with target blank and noopener" do
    rendered = render_inline(described_class.new(url: "https://example.com/guide", text: "Vanlife Guide"))

    expect(rendered.to_html).to have_link("Vanlife Guide", href: "https://example.com/guide")

    link = rendered.css("a").first
    expect(link[:target]).to eq("_blank")
    expect(link[:rel]).to include("noopener")
  end
end
