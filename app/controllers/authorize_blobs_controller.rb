# REFACTOR: replace the PicturesOnlyController with this controller?
# REFACTOR: take visibility status into account?
#
class AuthorizeBlobsController < ApplicationController
  include ActiveStorage::SetBlob

  skip_verify_authorized only: [:show] # NOTE: skip general verification, as we hand-rolles it for this special case
  before_action :authenticate_member!

  def show
    expires_in ActiveStorage.service_urls_expire_in # default is 5.minutes

    base_url = "http://localhost:3000/rails/active_storage/blobs/redirect/"
    # base_url = "http://localhost:3000/rails/active_storage/disk/"
    blob_url = base_url + @blob.signed_id + "/" + @blob.filename.to_s

    redirect_to blob_url

    # redirect to @blob.service_url # removed method?!
  end

  private

  # NOTE: raises 404 if current_user not member of the team that owns the picture blob
  #
  def authenticate_member!
    blob_owner = @blob.attachments.first.record.team
    current_user.memberships.find_by!(team: blob_owner)
  end
end
