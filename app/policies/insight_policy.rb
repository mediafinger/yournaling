class InsightPolicy < ApplicationPolicy
  def read?
    guest?
  end

  def create?
    current_team_owns_record? && with_role?(:owner, :manager, :editor)
  end

  def update?
    current_team_owns_record? && with_role?(:owner, :manager, :editor)
  end

  def destroy?
    current_team_owns_record? && with_role?(:owner, :manager)
  end
end
