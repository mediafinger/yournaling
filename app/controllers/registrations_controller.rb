# frozen_string_literal: true

# The public signup funnel. Thin by construction: everything that must hold true for a new account
# lives in UserRegistrationService, so that this controller cannot drift away from it.
#
class RegistrationsController < ApplicationController
  skip_before_action :authenticate, only: %i[new create]

  # Keyed by IP, which is the only identifier a signup request has not yet chosen for itself:
  # rate limiting by submitted email would be defeated by varying the email, which is precisely
  # what bulk account creation does.
  rate_limit to: 5, within: 1.hour, only: :create

  # GET /register
  def new
    @user = User.new
    authorize! @user, to: :new?, with: RegistrationPolicy
  end

  # POST /register
  def create
    # Authorising a fresh User rather than one built from params: the decision here is "may this
    # visitor register at all", which must not be influenced by attributes the visitor supplied.
    authorize! User.new, to: :create?, with: RegistrationPolicy

    @user = UserRegistrationService.call(attributes: registration_params)

    if @user.persisted?
      redirect_to login_path, notice: "Welcome! Please check your email to confirm your address."
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def registration_params
    params.expect(user: %i[name email password])
  end
end
