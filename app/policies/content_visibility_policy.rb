class ContentVisibilityPolicy < ApplicationPolicy
  def update?
    return false unless current_team_owns_record?

    return with_role?(:owner, :manager) if record.is_a?(Member)

    case record.visibility
    when "internal"
      with_role?(:owner, :manager, :editor, :publisher)
    when "published"
      with_role?(:publisher)
    when "archived"
      with_role?(:owner, :manager, :publisher)
    else
      false
    end
  end
end
