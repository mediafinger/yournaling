# frozen_string_literal: true

require "rails_helper"

RSpec.describe JoblessBannerComponent, type: :component do
  it "renders nothing outside development" do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("test"))

    expect(render_inline(described_class.new).to_html).to be_blank
  end

  context "in development" do
    before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development")) }

    it "renders an assertive orange alert with the bin/dev hint when no worker runs" do
      allow(JobsWorkerMonitor).to receive(:worker_running?).and_return(false)

      rendered = render_inline(described_class.new)

      expect(rendered).to have_css(".yui-toast--jobless[role='alert'][aria-live='assertive']")
      expect(rendered).to have_css(".yui-toast__title", text: "No background jobs are running")
      expect(rendered).to have_css("code", text: "bin/dev")
      expect(rendered).to have_css("button.yui-toast__dismiss[data-action='yui-toast#dismiss']")
    end

    it "renders nothing once a worker is running" do
      allow(JobsWorkerMonitor).to receive(:worker_running?).and_return(true)

      expect(render_inline(described_class.new).to_html).to be_blank
    end
  end
end
