# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminIndexRecordEventsComponent, type: :component do
  it "renders the record_events container" do
    rendered = render_inline(described_class.new(record_events: []))

    expect(rendered.css("div#record_events")).to be_present
  end

  it "evaluates the loop instead of leaking the template source as text" do
    # Regression: the inline template used a non-squiggly heredoc and was missing
    # the leading `-` before `.each`, so Slim printed the Ruby line verbatim.
    rendered = render_inline(described_class.new(record_events: []))

    expect(rendered.to_html).not_to include("record_events.each")
    expect(rendered.to_html).not_to include("= render AdminShowRecordEventComponent")
  end
end
