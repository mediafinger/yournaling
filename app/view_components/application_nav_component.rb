# frozen_string_literal: true

class ApplicationNavComponent < ApplicationComponent
  slim_template <<~'SLIM'
    ul
      li
        = link_to "🌐 Yournaling", root_path, role: active_path?(root_path) ? "button" : nil
      - if current_team
        li
          = link_to "⚙️ Manage #{current_team.name}", current_team_home_path
      = render NavNewButtonComponent.new(mode: :browse)

    ul
      - if current_team || params[:team_id].present?
        - target = params[:team_id] || current_team
        li
          = link_to "@Teams", teams_path, role: (active_path?(teams_path) && !active_path?(team_members_path(target))) ? "button" : nil
        li
          = link_to "@@Members", team_members_path(target), role: active_path?(team_members_path(target)) ? "button" : nil
      - else
        li
          = link_to "@Teams", teams_path, role: active_path?(teams_path) ? "button" : nil
      li
        = link_to "🔍 Search", new_search_path, role: active_path?(new_search_path) ? "button" : nil

    = render TeamSwitcherAndSessionsComponent.new(mode: :browse)
  SLIM

  def initialize(params: {})
    @params = params
  end
end
