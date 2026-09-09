class UserPolicy < ApplicationPolicy
  def create?
    guest?
  end

  # TODO: define own policy - to not require any team or membership
  def destroy?
    current_team_owns_record? # in case of User validates if current_user == record
  end
end
