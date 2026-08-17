# frozen_string_literal: true

require "rails_helper"

RSpec.describe Pagy do
  it "configures Pagy limit to match AppConf.items_per_page" do
    expect(described_class::OPTIONS[:limit]).to eq(AppConf.items_per_page)
  end

  it "includes Pagy::Method in ApplicationController" do
    expect(ApplicationController.ancestors).to include(described_class::Method)
  end
end
