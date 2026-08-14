# frozen_string_literal: true

class CurrentTeamNavComponent < ApplicationComponent
  slim_template <<~SLIM
    ul
      li
        = link_to "Browse Mode", "/"
      - if current_team
        li
          strong
            = link_to current_team.name, current_team_home_path, role: active_path?(current_team_home_path) ? "button" : nil
      li
        = link_to "Search", current_team_new_search_path, role: active_path?(current_team_new_search_path) ? "button" : nil

    = render ApplicationNavLinksComponent.new(link_sections: @sections, scope: "current_team")
    = render ApplicationNavActionsComponent.new(actions_for: @sections, scope: "current_team")

    = render TeamSwitcherComponent.new
  SLIM

  def initialize
    @sections = %w[memories thoughts pictures locations weblinks members]
  end
end
