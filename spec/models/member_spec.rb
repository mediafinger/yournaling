require "rails_helper"

RSpec.shared_examples "has_role?" do |role|
  it "#{role}? returns true when role #{role} is set" do
    member.add_role(role.to_sym)

    expect(member.public_send("#{role}?".to_sym)).to be true
  end

  it "#{role}? returns false when role #{role} is not set" do
    expect(member.public_send("#{role}?")).to be false
  end
end

RSpec.describe Member, type: :model do
  let(:member) { FactoryBot.create(:member, roles: []) }

  describe "roles" do
    let(:valid_role)   { Member::VALID_ROLES.sample }
    let(:invalid_role) { "thief" }

    Member::VALID_ROLES.each { |role| include_examples("has_role?", role) }

    describe "#add_role" do
      it "returns self" do
        expect(member.add_role(invalid_role)).to eq(member)
      end

      it "does not update the record in the database" do
        member.add_role(valid_role)
        member.reload

        expect(member.roles).to be_empty
      end

      context "when valid" do
        it "is idempotent, adds the role only once", :aggregated_failures do
          expect(member.add_role(valid_role)).to be_truthy

          member.add_role(valid_role)
          expect(member.roles).to eq(Array(valid_role))
        end
      end

      context "when invalid" do
        it "ensures only whitelisted roles are saved" do
          expect { member.add_role(invalid_role) }.not_to raise_error
          expect(member.errors).not_to be_empty
          expect(member.reload.roles).to be_empty
        end
      end
    end

    describe "#add_role!" do
      context "when valid" do
        it "is idempotent, adds the role only once", :aggregated_failures do
          expect(member.add_role!(valid_role)).to be_truthy

          member.add_role!(valid_role)

          expect(member.roles).to eq(Array(valid_role))
        end
      end

      context "when invalid" do
        it "ensures only whitelisted roles are saved, ignores invalid roles" do
          expect { member.add_role!(invalid_role) }.not_to raise_error
          expect(member.reload.roles).to be_empty
        end
      end
    end

    describe "#delete_role" do
      subject(:member) { FactoryBot.create(:member, roles: [valid_role]) }

      it "returns self" do
        expect(member.delete_role(valid_role)).to eq(member)
      end

      it "does not update the record in the database" do
        member.delete_role(valid_role)
        member.reload

        expect(member.roles).to eq([valid_role])
      end

      it "removes an existing role" do
        member.delete_role(valid_role)

        expect(member.roles).to eq([])
      end

      it "is idempotent, does not raise when the member does not have the role" do
        member.delete_role(valid_role)
        member.delete_role(valid_role)

        expect(member.roles).to eq([])
      end
    end

    describe "#delete_role!" do
      subject(:member) { FactoryBot.create(:member, roles: [valid_role]) }

      it "removes an existing role" do
        member.delete_role!(valid_role)

        expect(member.roles).to eq([])
      end

      it "is idempotent, does not raise when the member does not have the role" do
        member.delete_role!(valid_role)
        member.delete_role!(valid_role)

        expect(member.roles).to eq([])
      end
    end

    # direct usage is discouraged, has to work properly nevertheless
    describe "#roles=" do
      context "when valid" do
        it "works", :aggregated_failures do
          member.roles = Array(valid_role)

          expect(member.save!).to be_truthy
        end
      end

      context "when invalid" do
        it "ensures only whitelisted roles are saved" do
          member.roles = Array(invalid_role)

          expect { member.save! }.to raise_error(ActiveRecord::RecordInvalid)
          expect(member.reload.roles).to be_empty
        end
      end
    end
  end
end
