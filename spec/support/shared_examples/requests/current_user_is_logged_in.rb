# frozen_string_literal: true

RSpec.shared_examples_for "current user is logged in" do
  # expects the following variables to be defined in the calling spec:
  # (let() and values only examples!)
  #
  # let(:user) { create(:user) }
  # let(:owned_record) { user }
  # let(:unassociated_record) { create(:user) }
  # let(:policy_class) { described_class }
  # let(:rule) { read? }
  #

  # logged_in?
  #
  describe "#rule" do
    subject(:allowed_to?) { policy.apply(rule) }

    let(:policy) { policy_class.new(record, user: user, team: nil, member: nil) }

    describe "when the record is not owned by the user" do
      let(:record) { unassociated_record }

      it "returns true" do
        expect(allowed_to?).to be true # use current_team_owns_record? to prevent this
      end
    end

    describe "when the record is owned by the user" do
      let(:record) { owned_record }

      it "returns true" do
        expect(allowed_to?).to be true
      end
    end
  end
end
