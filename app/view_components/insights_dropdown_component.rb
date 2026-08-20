# frozen_string_literal: true

class InsightsDropdownComponent < ApplicationComponent
  slim_template <<~SLIM
    details.dropdown
      summary role=(active? ? "button" : nil) Insights
      ul
        - if @scope == :admin
          li
            = link_to "Pictures", admin_pictures_path, role: active_path?(admin_pictures_path) ? "button" : nil
          li
            = link_to "Locations", admin_locations_path, role: active_path?(admin_locations_path) ? "button" : nil
          li
            = link_to "Thoughts", admin_thoughts_path, role: active_path?(admin_thoughts_path) ? "button" : nil
          li
            = link_to "Weblinks", admin_weblinks_path, role: active_path?(admin_weblinks_path) ? "button" : nil
        - else
          li
            = link_to "Pictures", current_team_pictures_path, role: active_path?(current_team_pictures_path) ? "button" : nil
          li
            = link_to "Thoughts", current_team_thoughts_path, role: active_path?(current_team_thoughts_path) ? "button" : nil
          li
            = link_to "Locations", current_team_locations_path, role: active_path?(current_team_locations_path) ? "button" : nil
          li
            = link_to "Weblinks", current_team_weblinks_path, role: active_path?(current_team_weblinks_path) ? "button" : nil
  SLIM

  def initialize(scope: :current_team)
    @scope = scope.to_sym
  end

  def active?
    if @scope == :admin
      active_path?(admin_pictures_path) ||
        active_path?(admin_locations_path) ||
        active_path?(admin_thoughts_path) ||
        active_path?(admin_weblinks_path)
    else
      active_path?(current_team_pictures_path) ||
        active_path?(current_team_thoughts_path) ||
        active_path?(current_team_locations_path) ||
        active_path?(current_team_weblinks_path)
    end
  end
end
