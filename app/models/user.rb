# frozen_string_literal: true

class User < ApplicationRecordYidEnabled
  USER_ROLES = [
    "admin", # can access the jobs interface and other internal UIs, is also editor, moderator and account_manager
    "account_manager", # can create and manage teams and users and is an editor
    "moderator", # can flag, hide, edit content that violates the TOS and flag or block users and is an editor
    "editor", # can update content of the homepage and I18n resources
    "user", # the default role, a user without any special permissions
  ].freeze
  YID_CODE = "user"

  # TODO: check if we want validations: https://api.rubyonrails.org/classes/ActiveModel/SecurePassword/ClassMethods.html
  has_secure_password :password, validations: false

  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end

  generates_token_for :email_change, expires_in: 2.hours do
    email
  end

  EMAIL_VERIFICATION_TOKEN_VALIDITY = 3.days

  # Embedding both the address and the verification timestamp in the payload makes the token
  # single-use (redeeming it changes email_verified_at) and dead on an address change.
  generates_token_for :email_verification, expires_in: EMAIL_VERIFICATION_TOKEN_VALIDITY do
    [email, email_verified_at&.to_i].join(":")
  end

  has_many :logins, inverse_of: :user, dependent: :delete_all
  has_many :memberships, class_name: "Member", inverse_of: :user, dependent: :destroy
  has_many :events, class_name: "RecordEvent", inverse_of: :user, dependent: :delete_all
  has_many :visits, class_name: "Ahoy::Visit", inverse_of: :user, dependent: :destroy

  has_many :teams, through: :memberships

  scope :email_verified, -> { where.not(email_verified_at: nil) }
  scope :email_unverified, -> { where(email_verified_at: nil) }

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :name, with: ->(name) { name.strip }
  normalizes :nickname, with: ->(nickname) { nickname.parameterize.underscore }

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "not valid" }
  validates :password, length: { in: 10..72 }, if: -> { password.present? } # 72 is a has_secure_password limitation
  # `has_secure_password validations: false` contributes no presence check, so state it here.
  # Scoped to :create because password_digest, not password, is what a persisted record carries;
  # an update that does not touch the password must stay valid.
  validates :password, presence: true, on: :create
  # On create the rule above already implies a digest (the password= setter writes it), so keeping
  # this unscoped would only add a second, jargon-laden error to the signup form.
  validates :password_digest, presence: true, on: :update
  validates :name, presence: true, length: { in: 3..72 } # display optionally, nickame required for posting anything
  validates :nickname, allow_nil: true, uniqueness: true, length: { in: 7..72 } # make users pay for shorter nicknames
  validates :preferences, presence: true, if: proc { |record| record.preferences.to_s == "" }
  validates :role, presence: true, array_inclusion: {
    in: USER_ROLES, message: "%{rejected_values} not allowed, role must be in #{USER_ROLES}"
  } # this uses the custom ArrayInclusionValidator

  # defines admin?, account_manager?, moderator?, editor?, user? predicates
  USER_ROLES.each do |user_role|
    define_method(:"#{user_role}?") { role.to_s == user_role }
  end

  def email_verified?
    email_verified_at.present?
  end

  # Idempotent on purpose: a verification link that is prefetched by an email scanner and then
  # clicked by the user must not move the timestamp, or the second visit would look like a replay.
  def verify_email!
    return true if email_verified?

    update!(email_verified_at: Time.current)
  end
end
