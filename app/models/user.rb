class User < ApplicationRecord
  SEPARATOR = "::".freeze

  has_secure_password :password, validations: false

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "not valid" }
  validates :password, length: { in: 10..72 }, on: %i(create reset_password) # 72 is a has_secure_password limitation
  validates :name, length: { in: 3..255 }

  class << self
    def authenticate_temp_auth_token!(base64)
      expires_at, token = Base64.urlsafe_decode64(base64.to_s).split(SEPARATOR)
      raise(StandardError, "Token invalid, please restart your operation") if expires_at.nil? || token.nil?
      raise(StandardError, "Token expired, please restart your operation") if Time.zone.now > Time.parse(expires_at)

      user = User.find_by(temp_auth_token: base64)
      raise(StandardError, "Token unknown, please restart your operation") unless user

      # returning the user means authorizing the operation, e.g. email confirmation or password reset
      user.update!(temp_auth_token: nil) # additionally a job to delete all outdated tokens would be nice
      user
    end
  end

  def generate_temp_auth_token!(expires_at: 10.minutes.from_now)
    raise(StandardError, "Expiration date too far in the future") if expires_at > 24.hours.from_now

    token = Base64.urlsafe_encode64("#{expires_at}#{SEPARATOR}#{SecureRandom.uuid}")
    self.update!(temp_auth_token: token)
    token
  end
end
