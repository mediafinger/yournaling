# frozen_string_literal: true

RSpec.shared_examples_for "guest user" do
  # expects the following variables to be defined in the calling spec:
  # (let() and values only examples!)
  #
  # let(:user) { User.new }
  # let(:owned_record) { Comment.new }
  # let(:unassociated_record) { create(:user) }
  # let(:policy_class) { described_class }
  # let(:rule) { read? }
  #

  # guest?
  #
  describe "#rule" do
    subject(:allowed_to?) { policy.apply(rule) }

    let(:policy) { policy_class.new(record, user: user, team: nil, member: nil) }

    describe "when the record is not owned by the user" do
      let(:record) { unassociated_record }

      it "returns true" do
        expect(allowed_to?).to be true # Guest user can not own records
      end
    end

    describe "when the record is owned by the user" do
      let(:record) { owned_record } # Guest user can not own records, so this test is redundant

      it "returns true" do
        expect(allowed_to?).to be true
      end
    end
  end
end
