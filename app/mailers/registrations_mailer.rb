# frozen_string_literal: true

class RegistrationsMailer < ApplicationMailer
  def verify_email(user)
    @user = user
    @token = user.generate_token_for(:email_verification)

    mail to: @user.email, subject: "Please confirm your email address"
  end
end
