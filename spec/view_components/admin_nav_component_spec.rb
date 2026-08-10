# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminNavComponent, type: :component do
  let(:admin_user) { FactoryBot.create(:user, role: "admin") }

  before do
    allow_any_instance_of(described_class).to receive(:current_user).and_return(admin_user) # rubocop:disable RSpec/AnyInstance
  end

  it "renders leave admin button" do
    rendered = render_inline(described_class.new)
    expect(rendered.to_html).to have_link("Leave Admin Area", href: "/")
  end

  it "renders all resource navigation links" do
    rendered = render_inline(described_class.new)

    %w[users teams locations pictures thoughts weblinks members record_history].each do |section|
      expect(rendered.to_html).to have_link(section.titleize, href: "/admin/#{section}")
    end
  end
end
