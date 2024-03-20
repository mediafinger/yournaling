module ApplicationHelper
  include ActionView::Helpers::NumberHelper # for number_to_human_size
  include Authentication # makes current_user available
  include TeamScope # makes current_team & current_member available
  # include RequestContext # makes the Current.objects available

  # to highlight the active link in the navbar
  def active_path?(given_path)
    request.path.start_with?(given_path)
  end
end
