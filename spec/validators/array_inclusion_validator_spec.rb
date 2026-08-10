# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArrayInclusionValidator do
  before do
    model_class = Class.new do
      include ActiveModel::Model

      attr_accessor :tags, :numbers

      validates :tags, array_inclusion: { in: %w[ruby rails rspec] }
      validates :numbers, array_inclusion: { proc: ->(val) { val.is_a?(Integer) && val.positive? } }, allow_nil: true
    end

    stub_const("TestModelWithArrayInclusion", model_class)
  end

  it "is valid when all elements are included in the allowed list" do
    record = TestModelWithArrayInclusion.new(tags: %w[ruby rails], numbers: [1, 2, 3])
    expect(record).to be_valid
  end

  it "is invalid when an element is not in the allowed list" do
    record = TestModelWithArrayInclusion.new(tags: %w[ruby python])
    expect(record).not_to be_valid
    expect(record.errors[:tags]).to be_present
  end

  it "is invalid when an element fails the proc validation" do
    record = TestModelWithArrayInclusion.new(tags: %w[ruby], numbers: [1, -5])
    expect(record).not_to be_valid
    expect(record.errors[:numbers]).to be_present
  end
end
