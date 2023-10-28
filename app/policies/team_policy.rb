class TeamPolicy < ApplicationPolicy
  def show?
    guest?
  end

  def index?
    logged_in?
  end

  def update?
    current_team_owns_record? && with_role?(:owner)
  end
end
