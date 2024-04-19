# This module creates a new Login record everytime a User logs in from a new device.
# If the device (== hashed IP address & user_agent) has been used before, the Login record will be updated.
# Older Login records of the same user will be deleted after every new login, we keep only
# NUMBER_OF_LOGIN_SESSIONS_TO_KEEP (currently: 3).
# Deleting a Login record invalidates the session - and effectively logs the user out from the other devices.
# When logging out, the Login record will also be deleted.
#
module Logins
  extend ActiveSupport::Concern

  NUMBER_OF_LOGIN_SESSIONS_TO_KEEP = 3 # handle this more restrictively and allow only 2 ?!

  def self.included(base)
    # before_action :logout_if_login_record_has_been_deleted
    base.send :before_action, :logout_if_login_record_has_been_deleted if base.respond_to? :before_action
  end

  def create_login
    return unless current_user.persisted?

    current_login = current_user.logins.find_or_initialize_by(ip_address: request.remote_ip, user_agent: request.user_agent)
    current_login.save!
    session[:device_id] = current_login.device_id

    delete_old_logins(user: current_user)
  end

  def destroy_login
    return unless current_user.persisted?

    current_user.logins.find_by(device_id: session[:device_id])&.destroy
    session.delete(:device_id)
  end

  def logout_if_login_record_has_been_deleted
    return unless current_user.persisted?
    return if controller_path == "sessions" && action_name == "create"

    current_login = current_user.logins.find_by(device_id: session[:device_id])
    return if current_login.present?

    sign_out

    redirect_to root_url
  end

  def delete_old_logins(user:)
    user.logins.order(updated_at: :desc).offset(NUMBER_OF_LOGIN_SESSIONS_TO_KEEP).delete_all
  end
end
