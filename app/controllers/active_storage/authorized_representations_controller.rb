# frozen_string_literal: true

module ActiveStorage
  class AuthorizedRepresentationsController < Representations::ProxyController
    include Authentication
    include ActiveStorageBlobAuthorization

    before_action :authorize_blob_access!
  end
end
