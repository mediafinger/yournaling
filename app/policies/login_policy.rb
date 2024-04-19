class LoginPolicy < ApplicationPolicy
  def index?
    logged_in?
  end

  # unused
  def show?
    destroy?
  end

  # unused
  def create?
    destroy?
  end

  # unused
  def update?
    destroy?
  end

  def destroy?
    logged_in? && record.user == user
  end
end
