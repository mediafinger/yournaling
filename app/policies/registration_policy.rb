# frozen_string_literal: true

# Governs self-service account creation.
#
# Distinct from UserPolicy on purpose: UserPolicy#create? answers "may this actor create a User
# record?" (an admin may), whereas registration is the *public* funnel and must be closed to anyone
# who already holds a session -- otherwise a signed-in user can silently orphan their own account.
#
class RegistrationPolicy < ApplicationPolicy
  def create?
    !logged_in?
  end
end
