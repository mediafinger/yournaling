module ApplicationHelper
  # for number_to_human_size
  include ActionView::Helpers::NumberHelper

  # to highlight the active link in the navbar
  def active_path?(given_path)
    request.path.start_with?(given_path)
  end
end
