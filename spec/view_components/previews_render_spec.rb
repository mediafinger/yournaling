# frozen_string_literal: true

require "rails_helper"

# Smoke test: every Lookbook preview example must render without raising.
# Lookbook itself is dev-only, so nothing else exercises these files in CI.
RSpec.describe "ViewComponent previews", type: :component do # rubocop:disable RSpec/DescribeClass
  ViewComponent::Preview.all.each do |preview| # rubocop:disable Rails/FindEach -- Array, not a relation
    preview.examples.each do |example|
      it "#{preview.preview_name}/#{example} renders" do
        expect { render_preview(example, from: preview) }.not_to raise_error
      end
    end
  end
end
