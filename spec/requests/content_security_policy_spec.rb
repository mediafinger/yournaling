# frozen_string_literal: true

require "rails_helper"

# The CSP is enabled outside development (Phase 6). It is enforced in test, so
# this also guards that the header stays well-formed.
RSpec.describe "Content Security Policy", type: :request do
  it "sends a locked-down policy on a normal page" do
    get "/up"

    csp = response.headers["Content-Security-Policy"]
    expect(csp).to be_present
    expect(csp).to include("default-src 'self'")
    expect(csp).to include("object-src 'none'")
    expect(csp).to include("frame-ancestors 'self'")
    expect(csp).to include("base-uri 'self'")
  end

  it "allows no external script, style or font host" do
    get "/up"

    csp = response.headers["Content-Security-Policy"]
    expect(csp).to include("script-src 'self' 'unsafe-inline'")
    expect(csp).to include("style-src 'self' 'unsafe-inline'")
    expect(csp).to include("font-src 'self'")
    expect(csp).not_to include("https:")
    expect(csp).not_to include("http:")
  end
end
