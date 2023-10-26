module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user

    before_action :authenticate
  end

  def sign_in(email:, password:)
    user = User.authenticate_by(email:, password:)

    if user.present?
      reset_session
      session[:user_yid] = user.urlsafe_id
      @current_user = user
      initialize_request_context # to refresh the Current objects directly
    end

    current_user
  end

  def sign_out
    reset_session
    @current_user = guest_user
    initialize_request_context # to refresh the Current objects directly
    current_user
  end

  private

  def authenticate(allow_guest: true)
    return if current_user.present? && (current_user.persisted? || allow_guest)

    session[:return_to] ||= request.referer
    redirect_to :login
  end

  def current_user
    @current_user ||= session[:user_yid] ? User.urlsafe_find(session[:user_yid]) : guest_user
  end

  def guest_user
    User.new(name: "Guest")
  end
end
