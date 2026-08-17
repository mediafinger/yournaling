# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  include ActionPolicy::Behaviour
  include Authentication # makes current_user available
  include TeamScope # makes current_team & current_member available
  # include RequestContext # makes the Current.objects available
  include ApplicationHelper

  authorize :user, through: :current_user
  authorize :team, through: :current_team
  authorize :member, through: :current_member
end
