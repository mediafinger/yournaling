module RequestContext
  extend ActiveSupport::Concern

  def self.included(base)
    base.send :before_action, :initialize_request_context if base.respond_to? :before_action
    # base.send :before_action, :set_sentry_context # uncomment when hosting and using Sentry
  end

  private

  def initialize_request_context
    Current.user = current_user
    Current.team = current_team
    Current.member = current_member

    Current.module_name = self.class.module_parent_name
    Current.path = request.path
    Current.request_id = request.request_id # set via middleware gem Rack::RequestID and/or ActionDispatch::RequestId
  end

  # uncomment when hosting and using Sentry
  #
  # def set_sentry_context
  #   Sentry.set_user(id: Current.user&.id)
  #
  #   Sentry.configure_scope do |scope|
  #     scope.set_extras(
  #       request_id: Current.request_id
  #       params: request.filtered_parameters,
  #
  #       user_id: Current.user&.id
  #       team_id: Current.team&.id,
  #       member_id: Current.member&.id,
  #       member_roles: Current.member&.roles,
  #     )
  #   end
  # end
end
