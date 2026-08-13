# frozen_string_literal: true

require "rails_helper"

RSpec.describe PasswordsMailer, type: :mailer do
  describe "#password_reset" do
    let(:user) { FactoryBot.create(:user, name: "Alice", email: "alice@example.com") }
    let(:mail) { described_class.password_reset(user) }

    it "renders the headers" do
      expect(mail.subject).to eq("Password Reset Instructions")
      expect(mail.to).to eq(["alice@example.com"])
      expect(mail.from).to eq(["no-reply@yournaling.com"])
    end

    it "renders the body with reset link" do
      expect(mail.body.encoded).to include("Hello Alice")
      expect(mail.body.encoded).to include("user_password/edit/")
    end
  end
end
