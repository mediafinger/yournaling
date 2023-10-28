# Base class for application policies
class ApplicationPolicy < ActionPolicy::Base
  NON_TEAM_OWNED_RECORD_CLASSES = %w[
    User
  ].freeze

  # Configure additional authorization contexts here
  # authorize :user, optional: false # (`user` is added by default).
  #
  # to have the current_team automagically available as 'team' here
  # add to the ApplicationController: authorize :team, through: :current_team
  #
  authorize :team, allow_nil: true # optional: true
  authorize :member, allow_nil: true # optional: true
  #
  # Read more about authorization context: https://actionpolicy.evilmartians.io/#/authorization_context

  #
  # Default Rules for all inheriting policiy classes
  #
  alias_rule :show?, :index?, to: :read?
  alias_rule :new?, to: :create?
  alias_rule :edit?, to: :update?

  def read?
    guest?
  end

  def create?
    logged_in?
  end

  def update?
    current_team_owns_record?
  end

  def destroy?
    current_team_owns_record? && with_role?(:owner)
  end

  #
  # for index action / for collections
  # named scope "current_team_scope" (without a name it would be the default scope)
  # usage: records = authorized_scope(Model.all, type: :relation, as: :current_team_scope)
  #
  # refactor to `do |relation, options|` if more flexibility is needed
  # then call with argument: `scope_options: { options: ... }`
  #
  scope_for :relation, :current_team_scope do |relation|
    # raise AuthError unless team.present?
    return relation.none unless team.present?
    return relation.none unless member.present? && member.team == team && member.user == user

    if relation.klass.name == ("Team")
      relation.where(yid: team.yid)
    elsif NON_TEAM_OWNED_RECORD_CLASSES.include?(relation.klass.name)
      relation.where(yid: user.yid) if relation.klass.name == "User"
    else
      relation.where(team:)
    end
  end

  private

  # Define shared methods useful for most policies.
  # For example:
  #
  #  def owner?
  #    record.user_id == user.id
  #  end

  def guest?
    true # allow access to anyone
  end

  def logged_in?
    user.persisted?
  end

  def current_team_owns_record?
    return false if record.nil?
    return false unless logged_in?

    if NON_TEAM_OWNED_RECORD_CLASSES.include?(record.class.name)
      record == user if record.is_a?(User)
    else
      return false unless team.present?
      return false unless member.present?
      return false unless member.user == user
      return false unless member.team == team

      record.is_a?(Team) ? record == team : record.team == team
    end
  end

  def with_role?(*roles)
    roles.any? { |role| member&.roles&.include?(role.to_s) }
  end
end
