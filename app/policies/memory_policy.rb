class MemoryPolicy < ApplicationPolicy
  def read?
    return true if current_team_owns_record?

    record.published?
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
