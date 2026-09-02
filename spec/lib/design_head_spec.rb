# frozen_string_literal: true

require "rails_helper"

# Guard: every stylesheet in app/assets/stylesheets/design/ must be listed in
# shared_partials/_design_head, so a new `tooltip.css` cannot be silently
# forgotten (TODO_UI_DESIGN.md §4). An asset-config guard, not a view spec —
# lives under spec/lib/ so spec/views/ can be retired entirely.
RSpec.describe "shared_partials/_design_head" do # rubocop:disable RSpec/DescribeClass
  let(:partial) { Rails.root.join("app/views/shared_partials/_design_head.html.slim").read }
  let(:listed) { partial.scan(/%w\[([^\]]+)\]/).flatten.join(" ").split }
  let(:on_disk) do
    Rails.root.glob("app/assets/stylesheets/design/*.css").map { |f| File.basename(f, ".css") }
  end

  it "references every design/*.css file exactly once" do
    expect(listed.sort).to eq(listed.uniq.sort)
    expect(listed.to_set).to eq(on_disk.to_set)
  end

  it "loads tokens.css first so the @layer order declaration wins" do
    expect(listed.first).to eq("tokens")
  end

  it "keeps showcase.css out of the app-wide set" do
    app_sheets = partial[/app_sheets = %w\[([^\]]+)\]/, 1].split
    expect(app_sheets).not_to include("showcase")
  end
end
