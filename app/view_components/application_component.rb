class ApplicationComponent < ViewComponent::Base
  include Authentication # makes current_user available
  include TeamScope # makes current_team & current_member available
  # include RequestContext # makes the Current.objects available
  include ApplicationHelper
end
