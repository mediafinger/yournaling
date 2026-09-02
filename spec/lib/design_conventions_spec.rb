# frozen_string_literal: true

require "rails_helper"

# Guards the "Component & template conventions" from TODO_UI_DESIGN.md §7 so a
# future template can't quietly reintroduce the patterns the migration removed.
RSpec.describe "design system conventions" do # rubocop:disable RSpec/DescribeClass
  let(:component_rb) { Rails.root.glob("app/view_components/**/*.rb") }

  # The showcase (`/example` + its Example:: chrome) is a design playground and
  # is allowed one-off inline styles / demo markup.
  let(:slim_templates) do
    (Rails.root.glob("app/views/**/*.slim") + Rails.root.glob("app/view_components/**/*.slim"))
      .reject { |f| f.to_s.include?("/example/") }
  end

  it "uses no `<<-SLIM` or bare `<<SLIM` heredocs (only `<<~SLIM` / `<<~'SLIM'`)" do
    offenders = Rails.root.glob("app/**/*.rb").select do |file|
      file.each_line.any? { |line| line !~ /^\s*#/ && line.match?(/<<-['"]?SLIM|<<['"]?SLIM\b/) }
    end

    expect(offenders).to be_empty, "squiggly heredocs only:\n#{offenders.join("\n")}"
  end

  it "keeps no inline `slim_template` in view components (sidecar `.slim` is the rule)" do
    offenders = component_rb.select { |file| file.read.match?(/^\s*slim_template\b/) }

    expect(offenders).to be_empty, "move these to a sidecar .html.slim:\n#{offenders.join("\n")}"
  end

  it "has no inline `style=` attributes in app templates" do
    offenders = slim_templates.select { |file| file.read.match?(/\bstyle=/) }

    expect(offenders).to be_empty, "style belongs in design/*.css:\n#{offenders.join("\n")}"
  end

  it "references only `--yui-*` custom properties in design/*.css" do
    stray = Rails.root.glob("app/assets/stylesheets/design/**/*.css").select do |file|
      file.read.match?(/--ex-|--pico-/)
    end

    expect(stray).to be_empty, "renamed to --yui-*:\n#{stray.join("\n")}"
  end
end
