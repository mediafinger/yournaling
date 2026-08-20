# frozen_string_literal: true

class TeamSwitcherAndSessionsComponent < ApplicationComponent
  slim_template <<~'SLIM'
    ul
      - if @mode != :admin && current_user&.admin?
        li
          = link_to "🛡️ Admin Area", "/admin", role: active_path?("/admin") ? "button" : nil
      - if @mode == :admin
        li
          span.scope-to-team Scope to Team
      - if current_user&.persisted?
        - if current_user.teams.any? && @mode != :admin
          li
            = link_to "Switch Team", switch_current_teams_path, role: active_path?(switch_current_teams_path) ? "button" : nil
        li
          = link_to "👤 #{current_user.name}", login_records_path, role: active_path?(login_records_path) ? "button" : nil
        li
          = link_to "Logout", logout_path, data: { turbo_method: :delete }, role: "link", class: "logout"
      - else
        li
          = link_to "Login", login_path, role: active_path?(login_path) ? "button" : nil
  SLIM

  def initialize(mode: :browse)
    @mode = mode.to_sym
  end
end
