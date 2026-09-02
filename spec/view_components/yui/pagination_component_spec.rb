# frozen_string_literal: true

require "rails_helper"

RSpec.describe Yui::PaginationComponent, type: :component do
  def pagy(count:, page:, limit: 20)
    Pagy::Offset.new(count:, page:, limit:)
  end

  let(:url) { ->(page) { "/admin/things?page=#{page}" } }

  it "renders nothing for a single page" do
    rendered = render_inline(described_class.new(pagy: pagy(count: 5, page: 1), url:))

    expect(rendered.to_html).to be_blank
  end

  it "renders a nav with the current page marked and the others linked" do
    rendered = render_inline(described_class.new(pagy: pagy(count: 235, page: 5), url:))

    expect(rendered).to have_css("nav.ex-pagination[aria-label='Pagination']")
    expect(rendered).to have_css("span.ex-pagination__link--current[aria-current='page']", text: "5")
    expect(rendered).to have_link("6", href: "/admin/things?page=6")
  end

  it "disables the prev control on the first page and links it elsewhere" do
    first = render_inline(described_class.new(pagy: pagy(count: 235, page: 1), url:))
    expect(first).to have_css("span.ex-pagination__link--nav[aria-disabled='true']", count: 1)
    expect(first).to have_link("Next page", href: "/admin/things?page=2")

    mid = render_inline(described_class.new(pagy: pagy(count: 235, page: 5), url:))
    expect(mid).to have_link("Previous page", href: "/admin/things?page=4")
    expect(mid).to have_link("Next page", href: "/admin/things?page=6")
  end

  it "inserts gaps for large page counts" do
    rendered = render_inline(described_class.new(pagy: pagy(count: 1000, page: 25), url:))

    expect(rendered).to have_css("span.ex-pagination__gap", minimum: 1)
    expect(rendered).to have_link("1", href: "/admin/things?page=1")
    expect(rendered).to have_link("50", href: "/admin/things?page=50")
  end

  it "falls back to pagy.page_url when no url proc is given" do
    pgy = pagy(count: 100, page: 2)
    allow(pgy).to receive(:page_url) { |n| "/fallback?p=#{n}" }

    rendered = render_inline(described_class.new(pagy: pgy))

    expect(rendered).to have_link("3", href: "/fallback?p=3")
  end
end
