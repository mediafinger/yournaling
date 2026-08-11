# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Active Storage Proxy Mode Authorization", type: :request do
  let(:team) { FactoryBot.create(:team) }
  let(:other_team) { FactoryBot.create(:team) }

  let(:owner_user) { FactoryBot.create(:user) }
  let(:member_user) { FactoryBot.create(:user) }
  let(:other_team_user) { FactoryBot.create(:user) }
  let(:admin_user) { FactoryBot.create(:user, role: "admin") }

  let!(:owner_membership) { Member.create!(team: team, user: owner_user, roles: %w[owner]) }
  let!(:member_membership) { Member.create!(team: team, user: member_user, roles: %w[editor]) }
  let!(:other_membership) { Member.create!(team: other_team, user: other_team_user, roles: %w[owner]) }

  let(:internal_picture) { FactoryBot.create(:picture, team: team, visibility: "internal") }
  let(:published_picture) { FactoryBot.create(:picture, team: team, visibility: "published") }
  let(:archived_picture) { FactoryBot.create(:picture, team: team, visibility: "archived") }

  def proxy_blob_path(attached_file)
    rails_service_blob_proxy_path(
      signed_id: attached_file.signed_id,
      filename: attached_file.filename
    )
  end

  def proxy_variant_path(variant)
    rails_blob_representation_proxy_path(
      signed_blob_id: variant.blob.signed_id,
      variation_key: variant.variation.key,
      filename: variant.blob.filename
    )
  end

  describe "GET raw blob via proxy (/rails/active_storage/blobs/proxy/...)" do
    context "when unauthenticated (guest)" do
      it "forbids accessing internal picture blobs" do
        get proxy_blob_path(internal_picture.file)
        expect(response).to have_http_status(:forbidden)
      end

      it "allows accessing published picture blobs" do
        get proxy_blob_path(published_picture.file)
        expect(response).to have_http_status(:ok)
      end

      it "forbids accessing archived picture blobs" do
        get proxy_blob_path(archived_picture.file)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when authenticated as a member of another team" do
      before do
        post login_path, params: { email: other_team_user.email, password: "foobar1234" }
      end

      it "forbids cross-team access to internal picture blobs" do
        get proxy_blob_path(internal_picture.file)
        expect(response).to have_http_status(:forbidden)
      end

      it "allows cross-team access to published picture blobs" do
        get proxy_blob_path(published_picture.file)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when authenticated as a regular team member" do
      before do
        post login_path, params: { email: member_user.email, password: "foobar1234" }
      end

      it "allows accessing internal picture blobs of their own team" do
        get proxy_blob_path(internal_picture.file)
        expect(response).to have_http_status(:ok)
      end

      it "forbids accessing archived picture blobs for non-manager/owner members" do
        get proxy_blob_path(archived_picture.file)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when authenticated as a team owner" do
      before do
        post login_path, params: { email: owner_user.email, password: "foobar1234" }
      end

      it "allows accessing internal picture blobs" do
        get proxy_blob_path(internal_picture.file)
        expect(response).to have_http_status(:ok)
      end

      it "allows accessing archived picture blobs" do
        get proxy_blob_path(archived_picture.file)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when authenticated as a system administrator" do
      before do
        post login_path, params: { email: admin_user.email, password: "foobar1234" }
      end

      it "allows accessing any team's internal picture blobs" do
        get proxy_blob_path(internal_picture.file)
        expect(response).to have_http_status(:ok)
      end

      it "allows accessing any team's archived picture blobs" do
        get proxy_blob_path(archived_picture.file)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET image variant representation via proxy (/rails/active_storage/representations/proxy/...)" do
    context "when unauthenticated (guest)" do
      it "forbids accessing internal picture variant representations" do
        get proxy_variant_path(internal_picture.thumbnail)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when authenticated as a member of another team" do
      before do
        post login_path, params: { email: other_team_user.email, password: "foobar1234" }
      end

      it "forbids cross-team access to internal picture variant representations" do
        get proxy_variant_path(internal_picture.thumbnail)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when authenticated as a team member" do
      before do
        post login_path, params: { email: member_user.email, password: "foobar1234" }
      end

      it "allows accessing internal picture variant representations of their own team" do
        get proxy_variant_path(internal_picture.thumbnail)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
