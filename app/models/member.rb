# type: actually neither Content nor Post, but is treated very similar
#
# When creating a new User, create a Team for them.
# A User can invite other Users to join their Team.
# A User can leave any Team, as long as they are not the last User in the Team.
# A Team can only be destroyed if last owner decides to destroy the Team
#  while still being part of another team or if the last owner decides to destroy their whole Account.
#
# NOTE: Members inherit from ApplicationRecordForContentAndPosts as they are displayed under /teams
#
class Member < ApplicationRecordForContentAndPosts
  VALID_ROLES = [
    "owner", # owns the team, can invite/remove other users to/from the team, can manage everything team related
    "manager", # can manage all team related objects, change member roles (except owner) and invite readers
    "editor", # can create and update all team related objects, but not delete any
    "publisher", # can change the visibility of existing team related objects
    # future paid roles:
    # "creator", # can create memories with note, photo and location, but not update or delete those or any else
    # "reader", # can read all team wide published objects, but not create or update any
  ].freeze
  YID_CODE = "member".freeze

  belongs_to :team, inverse_of: :members, foreign_key: "team_yid"
  belongs_to :user, inverse_of: :memberships, foreign_key: "user_yid"

  scope :with_role, ->(role) { with_roles(Array(role)) }
  scope :with_roles, ->(roles) { where("roles @> ?", "{#{roles.join(',')}}") } # must have all roles
  scope :without_role, ->(role) { without_roles(Array(role)) }
  scope :without_roles, ->(roles) { where.not("roles @> ?", "{#{roles.join(',')}}") } # must not have any role

  # see: https://www.donnfelker.com/multitenant-pgsearch-how-to/
  multisearchable(
    against: %i[user_name team_name],
    additional_attributes: ->(member) { { team_yid: member.team_yid } }
  )

  attr_readonly :team_yid
  attr_readonly :user_yid

  scope :with_includes, -> { includes(:team) }

  validates :team_yid, presence: true, uniqueness: { scope: :user_yid }
  validates :user_yid, presence: true, uniqueness: { scope: :team_yid }
  validates :roles, presence: true, if: proc { |record| record.roles.to_s == "" }
  validates :roles, array_inclusion: {
    in: VALID_ROLES, message: "%{rejected_values} not allowed, roles must be in #{VALID_ROLES}"
  } # this uses the custom ArrayInclusionValidator
  validates :visibility, presence: true, inclusion: { in: VISIBILITY_STATES }

  after_initialize :define_has_role_methods

  delegate :name, :nickname, to: :user

  def add_role!(role)
    add_role(role).save!
  end

  def add_role(role)
    unless VALID_ROLES.include?(role.to_s)
      errors.add(:roles, "invalid role, must be in #{VALID_ROLES}")
      return self
    end

    roles << role.to_s
    roles.uniq!

    self
  end

  def delete_role!(role)
    delete_role(role).save!
  end

  def delete_role(role)
    self.roles = (roles - Array(role.to_s)).uniq
    self
  end

  def name
    user_name
  end

  def user_name
    user.name
  end

  def team_name
    team.name
  end

  private

  # defines owner?, manager?, editor?, publisher?, reader?  methods
  def define_has_role_methods
    VALID_ROLES.each do |role|
      self.class.send(:define_method, :"#{role}?") do
        roles.include?(role.to_s)
      end
    end
  end
end
