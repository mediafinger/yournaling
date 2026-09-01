# frozen_string_literal: true

# Primary nav for the admin area layout.
class AdminNavComponent < ApplicationComponent
  def teams_active?
    active_path?(admin_teams_path) && !active_path?(admin_members_path)
  end
end
