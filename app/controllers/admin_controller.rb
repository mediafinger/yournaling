class AdminController < ApplicationController
  skip_verify_authorized

  before_action :authenticate_admin!

  layout "admin_area"

  private

  def authenticate_admin!
    return true if current_user.admin?

    redirect_to root_url, alert: I18n.t("helpers.controller.unauthorized")
  end
end
