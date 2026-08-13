# frozen_string_literal: true

class PasswordsMailer < ApplicationMailer
  def password_reset(user)
    @user = user
    @token = user.generate_token_for(:password_reset)

    mail to: @user.email, subject: "Password Reset Instructions"
  end
end
