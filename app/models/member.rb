# When creating a new User, create a Team for them.
# A User can invite other Users to join their Team.
# A User can leave any Team, as long as they are not the last User in the Team.
# A Team can only be destroyed if last owner decides to destroy the Team
#  while still being part of another team or if the last owner decides to destroy their whole Account.

class Member < ApplicationRecord
  VALID_ROLES = [
    "owner", # owns the team, can invite/remove other users to/from the team, can manage everything team related
    "manager", # can manage all team related objects, change member roles (except owner) and invite readers
    "editor", # can create and update all team related objects, but not delete any
    "publisher", # can change the visibility of existing team related objects
    # future paid roles:
    # "creator", # can create memories with note, photo and location, but not update or delete those or any else
    # "reader", # can read all team wide published objects, but not create or update any
  ].freeze

  belongs_to :team, inverse_of: :members
  belongs_to :user, inverse_of: :memberships

  validates :team_id, presence: true, uniqueness: { scope: :user_id }
  validates :user_id, presence: true, uniqueness: { scope: :team_id }
  validates :roles, array_inclusion: {
    in: VALID_ROLES, message: "%{rejected_values} not allowed, roles must be in #{VALID_ROLES}"
  } # this uses the custom ArrayInclusionValidator

  after_initialize :define_has_role_methods

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
    self.roles -= Array(role.to_s)
    self
  end

  private

  # defines owner?, manager?, editor?, publisher?, reader?  methods
  def define_has_role_methods
    VALID_ROLES.each do |role|
      self.class.send(:define_method, "#{role}?".to_sym) do
        roles.include?(role.to_s)
      end
    end
  end
end
