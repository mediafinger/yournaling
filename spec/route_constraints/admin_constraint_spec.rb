# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminConstraint do
  let(:admin_user) { FactoryBot.create(:user, role: "admin") }
  let(:regular_user) { FactoryBot.create(:user, role: "user") }

  describe ".matches?" do
    it "returns true when session belongs to an admin user" do
      request = instance_double(ActionDispatch::Request, session: { user_id: admin_user.urlsafe_id })
      expect(described_class.matches?(request)).to be true
    end

    it "returns false when session belongs to a non-admin user" do
      request = instance_double(ActionDispatch::Request, session: { user_id: regular_user.urlsafe_id })
      expect(described_class.matches?(request)).to be false
    end

    it "returns false when session is empty" do
      request = instance_double(ActionDispatch::Request, session: {})
      expect(described_class.matches?(request)).to be false
    end

    it "returns false when session contains a non-existent user_id" do
      fake_urlsafe_id = Base64.urlsafe_encode64("user_2026-01-01T00:00:00.000000Z_000000000000")
      request = instance_double(ActionDispatch::Request, session: { user_id: fake_urlsafe_id })
      expect(described_class.matches?(request)).to be false
    end
  end
end
