# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchFormComponent, type: :component do
  let(:general_klass_options) { %w[Team Memory Location Picture Thought Weblink Member] }
  let(:current_team_klass_options) { %w[Memory Location Picture Thought Weblink Member] }

  it "renders a form with the given URL and legend" do
    rendered = render_inline(described_class.new(
      url: "/search",
      klass_options: general_klass_options,
      default_klass: "Team",
    ))

    expect(rendered.to_html).to have_css("form[action='/search']")
    expect(rendered.to_html).to have_text("Search")
  end

  it "renders the query input with Stimulus bindings" do
    rendered = render_inline(described_class.new(
      url: "/search",
      klass_options: general_klass_options,
      default_klass: "Team",
    ))

    expect(rendered.to_html).to have_css("input[name='query'][data-search-target='input']")
  end

  it "renders a select with all klass_options for the general search" do
    rendered = render_inline(described_class.new(
      url: "/search",
      klass_options: general_klass_options,
      default_klass: "Team",
    ))

    general_klass_options.each do |klass|
      expect(rendered.to_html).to have_css("option[value='#{klass}']")
    end
  end

  it "renders a select with current_team klass_options (no Team)" do
    rendered = render_inline(described_class.new(
      url: "/current_team/search",
      klass_options: current_team_klass_options,
      default_klass: "Member",
    ))

    expect(rendered.to_html).to have_no_css("option[value='Team']")
    expect(rendered.to_html).to have_css("option[value='Member'][selected]")
  end

  it "pre-fills the query when provided" do
    rendered = render_inline(described_class.new(
      url: "/search",
      klass_options: general_klass_options,
      default_klass: "Team",
      query: "sunset",
    ))

    expect(rendered.to_html).to have_css("input[name='query'][value='sunset']")
  end

  it "selects the given klass_name" do
    rendered = render_inline(described_class.new(
      url: "/search",
      klass_options: general_klass_options,
      default_klass: "Team",
      klass_name: "Location",
    ))

    expect(rendered.to_html).to have_css("option[value='Location'][selected]")
  end

  it "disables the submit button when query is shorter than 3 characters" do
    rendered = render_inline(described_class.new(
      url: "/search",
      klass_options: general_klass_options,
      default_klass: "Team",
      query: "ab",
    ))

    expect(rendered.to_html).to have_css("input[type='submit'][disabled]")
  end

  it "enables the submit button when query is 3+ characters" do
    rendered = render_inline(described_class.new(
      url: "/search",
      klass_options: general_klass_options,
      default_klass: "Team",
      query: "abc",
    ))

    expect(rendered.to_html).to have_css("input[type='submit']:not([disabled])")
  end

  it "accepts a custom form_legend" do
    rendered = render_inline(described_class.new(
      url: "/search",
      klass_options: general_klass_options,
      default_klass: "Team",
      form_legend: "Find Stuff",
    ))

    expect(rendered.to_html).to have_text("Find Stuff")
  end
end
