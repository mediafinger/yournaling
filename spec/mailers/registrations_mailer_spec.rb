# frozen_string_literal: true

require "rails_helper"

RSpec.describe RegistrationsMailer, type: :mailer do
  describe "#verify_email" do
    let(:user) { FactoryBot.create(:user, name: "Alice", email: "alice@example.com") }
    let(:mail) { described_class.verify_email(user) }

    it "renders the headers" do
      expect(mail.subject).to eq("Please confirm your email address")
      expect(mail.to).to eq(["alice@example.com"])
      expect(mail.from).to eq(["no-reply@yournaling.com"])
    end

    it "renders both a html and a text part" do
      expect(mail.html_part).to be_present
      expect(mail.text_part).to be_present
    end

    %w[html text].each do |part|
      it "greets the user and carries a redeemable verification link in the #{part} part" do
        body = mail.public_send(:"#{part}_part").body.to_s

        expect(body).to include("Alice")

        token = body[%r{email_verification/([^"'\s<]+)}, 1]

        expect(User.find_by_token_for(:email_verification, token)).to eq(user)
      end
    end
  end
end
