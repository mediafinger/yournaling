module ApplicationHelper
  # to highlight the active link in the navbar
  def active_path?(given_path)
    return true if request.path.start_with?(given_path)
  end
end
