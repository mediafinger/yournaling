class CurrentTeamPolicy < ApplicationPolicy
  def index?
    logged_in?
  end

  def show?
    current_team_owns_record?
  end

  def create?
    current_team_owns_record?
  end

  def destroy?
    current_team_owns_record?
  end
end
