class MemberPolicy < ApplicationPolicy
  def read?
    logged_in?
  end

  def create?
    current_team_owns_record? && with_role?(:owner)
  end

  def update?
    current_team_owns_record? && with_role?(:owner)
  end

  def destroy?
    current_team_owns_record? && (with_role?(:owner) || record.user == user)
  end
end
