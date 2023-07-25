class User < ApplicationRecordYidEnabled
  SEPARATOR = "::".freeze
  YID_MODEL = "user".freeze

  has_secure_password :password, validations: false

  has_many :memberships, class_name: "Member", foreign_key: "user_yid", inverse_of: :user, dependent: :destroy
  has_many :teams, through: :memberships

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "not valid" }
  validates :password, length: { in: 10..72 }, on: %i(create reset_password) # 72 is a has_secure_password limitation
  validates :password_digest, presence: true
  validates :name, presence: true, length: { in: 3..72 }
  validates :nickname, allow_nil: true, uniqueness: true, length: { in: 3..72 }
  validates :preferences, presence: true, if: proc { |record| record.preferences.to_s == "" }

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
