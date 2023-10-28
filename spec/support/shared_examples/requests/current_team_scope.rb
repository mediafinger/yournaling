# frozen_string_literal: true

RSpec.shared_examples_for "current team scope" do
  # expects the following variables to be defined in the calling spec:
  #
  # policy_class => e.g.: SensorPolicy
  # scope_name => e.g.: :same_team_scope
  # relation => e.g.: Sensor (or e.g.: Project.undeleted)
  # user => e.g.: User.new
  # team => e.g.: Company.new
  # record => e.g.: :sensor
  #

  # relation.where(team_id: user_team_ids)
  describe "#scope" do
    subject(:scope_count) { scoped_policy.apply_scope(relation, type: :relation, name: scope_name).count }

    let(:scoped_policy) { policy_class.new(user: user, team: team, member: member) }

    before do
      # "Member" is a special case, as we create a Member record or expect none to exists for the user in the specs
      relation.klass.name == "Member" ? owned_record.destroy! : owned_record
      unassociated_record
    end

    context "when the user is not linked with the team" do
      let(:member) { nil }

      it "returns none" do
        expect(scope_count).to eq(0)
      end
    end

    context "when the user is associtated with the team" do
      let(:member) { FactoryBot.create(:member, team:, user:) }

      it "returns one" do
        expect(scope_count).to eq(1)
      end
    end
  end
end
