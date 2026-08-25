# frozen_string_literal: true

# Redeems email verification tokens, and re-issues them when the original mail never arrived.
#
# Both actions are open to guests by design: the bearer of a valid, unexpired token *is* the
# authorization, and the resend form has to work for someone who cannot sign in yet. There is no
# EmailVerificationPolicy for that reason -- a policy that answers `true` to every rule would be
# ceremony, not a control.
#
class EmailVerificationsController < ApplicationController
  # A spent token is indistinguishable from a forged one here, because redeeming a token rebinds
  # its payload and `find_by_token_for` then simply returns nil. Mail scanners prefetch links, so
  # a visitor seeing this may well be someone whose address is *already* confirmed -- the copy has
  # to route them to the login form rather than dead-ending them on a failure.
  INVALID_TOKEN_ALERT = "That confirmation link is no longer valid. " \
                        "If your address is already confirmed, please sign in; otherwise request a new link."
  # Deliberately non-committal, mirroring UserPasswordsController#create: the response must not
  # reveal whether the address is registered, nor whether it is already confirmed.
  RESEND_NOTICE = "If that address needs confirming, you will receive a new link shortly."

  skip_before_action :authenticate, only: %i[new create show]
  skip_verify_authorized only: %i[new create show]

  # Guards the mail sender, not the account: without this, one request per address turns this
  # endpoint into a mail bomb aimed at somebody else's inbox.
  rate_limit to: 3, within: 1.hour, only: :create

  # GET /email_verification/:token
  def show
    user = User.find_by_token_for(:email_verification, params[:token])

    return redirect_to(new_email_verification_path, alert: INVALID_TOKEN_ALERT) if user.blank?

    user.verify_email!

    redirect_to login_path, notice: "Your email address is confirmed. Please sign in."
  end

  # GET /email_verification/new
  def new
    @user = User.new
  end

  # POST /email_verification
  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)
    RegistrationsMailer.verify_email(user).deliver_later if user.present? && !user.email_verified?

    redirect_to login_path, notice: RESEND_NOTICE
  end
end
