class User < ApplicationRecordYidEnabled
  SEPARATOR = "::".freeze
  YID_CODE = "user".freeze

  # TODO: check if we want validations: https://api.rubyonrails.org/classes/ActiveModel/SecurePassword/ClassMethods.html
  has_secure_password :password, validations: false

  has_many :memberships, class_name: "Member", foreign_key: "user_yid", inverse_of: :user, dependent: :destroy

  has_many :teams, through: :memberships

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :name, with: ->(name) { name.strip }
  normalizes :nickname, with: ->(nickname) { nickname.strip }

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "not valid" }
  validates :password, length: { in: 10..72 }, on: %i[create reset_password] # 72 is a has_secure_password limitation
  validates :password_digest, presence: true
  validates :name, presence: true, length: { in: 3..72 }
  validates :nickname, allow_nil: true, uniqueness: true, length: { in: 3..72 }
  validates :preferences, presence: true, if: proc { |record| record.preferences.to_s == "" }
end
