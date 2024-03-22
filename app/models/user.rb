class User < ApplicationRecordYidEnabled
  USER_ROLES = [
    "admin", # can access the good_job interface and other internal UIs, is also editor, moderator and account_manager
    "account_manager", # can create and manage teams and users and is an editor
    "moderator", # can flag, hide, edit content that violates the TOS and flag or block users and is an editor
    "editor", # can update content of the homepage and I18n resources
    "user", # the default role, a user without any special permissions
  ].freeze
  YID_CODE = "user".freeze

  # TODO: check if we want validations: https://api.rubyonrails.org/classes/ActiveModel/SecurePassword/ClassMethods.html
  has_secure_password :password, validations: false

  has_many :memberships, class_name: "Member", foreign_key: "user_yid", inverse_of: :user, dependent: :destroy

  has_many :teams, through: :memberships

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :name, with: ->(name) { name.strip }
  normalizes :nickname, with: ->(nickname) { nickname.parameterize.underscore }

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "not valid" }
  validates :password, length: { in: 10..72 }, on: %i[create reset_password] # 72 is a has_secure_password limitation
  validates :password_digest, presence: true
  validates :name, presence: true, length: { in: 3..72 } # display optionally, nickame required for posting anything
  validates :nickname, allow_nil: true, uniqueness: true, length: { in: 7..72 } # make users pay for shorter nicknames
  validates :preferences, presence: true, if: proc { |record| record.preferences.to_s == "" }
  validates :role, presence: true, array_inclusion: {
    in: USER_ROLES, message: "%{rejected_values} not allowed, role must be in #{USER_ROLES}"
  } # this uses the custom ArrayInclusionValidator

  after_initialize :define_has_role_methods

  private

  # defines owner?, manager?, editor?, publisher?, reader?  methods
  def define_has_role_methods
    USER_ROLES.each do |user_role|
      self.class.send(:define_method, :"#{user_role}?") do
        role.to_s == user_role.to_s
      end
    end
  end
end
