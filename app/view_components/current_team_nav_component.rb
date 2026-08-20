# frozen_string_literal: true

class CurrentTeamNavComponent < ApplicationComponent
  slim_template <<~'SLIM'
    ul
      li
        = link_to "🌐 Yournaling", root_path
      - if current_team
        li
          = link_to "Manage #{current_team.name}", current_team_home_path, role: "button"
      = render NavNewButtonComponent.new(mode: :manage)

    ul
      li
        = link_to "Chronicles", current_team_chronicles_path, role: active_path?(current_team_chronicles_path) ? "button" : nil
      li
        = link_to "Memories", current_team_memories_path, role: active_path?(current_team_memories_path) ? "button" : nil
      li
        = render InsightsDropdownComponent.new(scope: :current_team)
      li
        = link_to "Members", current_team_members_path, role: active_path?(current_team_members_path) ? "button" : nil
      li
        = link_to "🔍 Search", current_team_new_search_path, role: active_path?(current_team_new_search_path) ? "button" : nil

    = render TeamSwitcherAndSessionsComponent.new(mode: :manage)
  SLIM
end
