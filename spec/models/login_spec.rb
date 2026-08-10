# frozen_string_literal: true

require "rails_helper"

RSpec.describe Login, type: :model do
  subject(:login) do
    described_class.new(
      user: user,
      ip_address: "192.168.1.100",
      user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"
    )
  end

  let(:user) { FactoryBot.create(:user) }

  describe "associations" do
    it "belongs to a user" do
      expect(login.user).to eq(user)
    end
  end

  describe "device_id generation" do
    it "automatically generates SHA256 device_id from ip_address and user_agent on creation" do
      login.save!
      expected_hash = Digest::SHA256.hexdigest("192.168.1.100 Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)")
      expect(login.device_id).to eq(expected_hash)
    end

    it "preserves existing device_id if already present" do
      custom_login = described_class.new(
        user: user,
        ip_address: "192.168.1.100",
        user_agent: "Mozilla/5.0",
        device_id: "predefined_device_token"
      )
      custom_login.save!
      expect(custom_login.device_id).to eq("predefined_device_token")
    end
  end

  describe "validations" do
    it "requires ip_address and user_agent" do
      invalid_login = described_class.new(user: user)
      expect(invalid_login).not_to be_valid
      expect(invalid_login.errors[:ip_address]).to be_present
      expect(invalid_login.errors[:user_agent]).to be_present
    end
  end
end
