# frozen_string_literal: true

class UserPasswordsController < ApplicationController
  skip_before_action :authenticate, only: %i[new create edit update]
  skip_verify_authorized only: %i[new create edit update]

  before_action :set_user_by_token, only: %i[edit update]

  # GET /user_password/new
  def new
    @user = User.new
  end

  # GET /user_password/edit/:token
  def edit
  end

  # POST /user_password
  def create
    user = User.find_by(email: params[:email])
    PasswordsMailer.password_reset(user).deliver_later if user.present?

    redirect_to login_path,
      notice: "If your email is in our database, you will receive password reset instructions shortly."
  end

  # PATCH /user_password/edit/:token
  def update
    @user.assign_attributes(password_params)

    if User.update_with_event(record: @user, event_params: { team: nil, user: @user })
      redirect_to login_path, notice: "Your password has been reset successfully. Please sign in."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_user_by_token
    @user = User.find_by_token_for(:password_reset, params[:token])
    return if @user.present?

    redirect_to new_user_password_path, alert: "That password reset link is invalid or has expired."
  end

  def password_params
    params.expect(user: %i[password])
  end
end
