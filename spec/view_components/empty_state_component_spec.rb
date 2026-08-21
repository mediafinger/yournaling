# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmptyStateComponent, type: :component do
  it "renders icon, title, description, and primary CTA button" do
    rendered = render_inline(
      described_class.new(
        icon: "💡",
        title: "No memories recorded yet",
        description: "Capture notes, thoughts, locations, and photos from your team journeys.",
        cta_label: "Create your first memory",
        cta_path: "/current_team/memories/new"
      )
    )

    expect(rendered.to_html).to include("💡")
    expect(rendered.to_html).to include("No memories recorded yet")
    expect(rendered.to_html).to include("Capture notes, thoughts, locations, and photos")
    expect(rendered.to_html).to have_link("Create your first memory", href: "/current_team/memories/new")
  end

  it "renders without CTA button when cta_path is not provided" do
    rendered = render_inline(
      described_class.new(
        icon: "📖",
        title: "No published stories yet",
        description: "Check back soon to see new travel chronicles."
      )
    )

    expect(rendered.to_html).to include("📖")
    expect(rendered.to_html).to include("No published stories yet")
    expect(rendered.to_html).to have_no_css("a[role='button']")
  end
end
