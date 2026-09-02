# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeviceComponent, type: :component do
  it "renders device and browser metadata from a desktop user agent" do
    ua = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36"
    rendered = render_inline(described_class.new(user_agent: ua))

    expect(rendered.to_html).to have_css("span.yui-text")
    expect(rendered.to_html).to include("Desktop", "Mac", "Chrome")
  end

  it "renders metadata from a smartphone user agent" do
    ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148 Safari/604.1"
    rendered = render_inline(described_class.new(user_agent: ua))

    expect(rendered.to_html).to have_css("span.yui-text")
    expect(rendered.to_html).to include("Smartphone", "iOS", "Mobile Safari")
  end
end
