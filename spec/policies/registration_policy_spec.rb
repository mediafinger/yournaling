# frozen_string_literal: true

RSpec.describe RegistrationPolicy do
  subject(:allowed_to?) { described_class.new(record, user: user, team: nil, member: nil).apply(rule) }

  let(:record) { User.new }

  %i[new? create?].each do |policy_rule|
    describe "##{policy_rule}" do
      let(:rule) { policy_rule }

      context "when the visitor is a guest" do
        let(:user) { User.new(name: "Guest") }

        it "returns true" do
          expect(allowed_to?).to be true
        end
      end

      context "when the visitor is already signed in" do
        let(:user) { FactoryBot.create(:user) }

        it "returns false, an account holder must log out before creating another account" do
          expect(allowed_to?).to be false
        end
      end
    end
  end
end
