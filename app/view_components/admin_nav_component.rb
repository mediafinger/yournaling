# frozen_string_literal: true

class AdminNavComponent < ApplicationComponent
  slim_template <<~SLIM
    ul
      li
        = link_to "🛡️ Admin Area", "/admin", role: active_path?("/admin") ? "button" : nil
      li
        = link_to "⬅ Exit Admin", root_path
      = render NavNewButtonComponent.new(mode: :admin)

    ul
      li
        = link_to "Users", admin_users_path, role: active_path?(admin_users_path) ? "button" : nil
      li
        = link_to "Teams", admin_teams_path, role: active_path?(admin_teams_path) && !active_path?(admin_members_path) ? "button" : nil
      li
        = link_to "Members", admin_members_path, role: active_path?(admin_members_path) ? "button" : nil
      li
        = link_to "Chronicles", admin_chronicles_path, role: active_path?(admin_chronicles_path) ? "button" : nil
      li
        = link_to "Memories", admin_memories_path, role: active_path?(admin_memories_path) ? "button" : nil
      li
        = render InsightsDropdownComponent.new(scope: :admin)
      li
        = link_to "Record Events", admin_record_events_path, role: active_path?(admin_record_events_path) ? "button" : nil
      li
        = link_to "Analytics", "/admin/blazer"
      li
        = link_to "Jobs", "/admin/jobs"

    = render TeamSwitcherAndSessionsComponent.new(mode: :admin)
  SLIM
end
