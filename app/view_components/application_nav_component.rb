# frozen_string_literal: true

class ApplicationNavComponent < ApplicationComponent
  slim_template <<~SLIM
    - if current_user&.admin?
      ul
        li
          = link_to "Admin Area", "/admin"

    - if current_team.present?
      ul
        li
          = @team_link_tag

    - if @team_scope
      = render ApplicationNavLinksComponent.new(link_sections: %w[chronicles memories members], scope: "team", id: { team_id: params[:team_id] })

    - if current_user.persisted?
      = render ApplicationNavLinksComponent.new(link_sections: %w[teams])

    ul
      li
        = link_to "Search", new_search_path, role: active_path?(new_search_path) ? "button" : nil

    - if current_user.persisted?
      = @login_records_link_tag

    = render TeamSwitcherComponent.new
  SLIM

  def initialize(params: {})
    @params = params
  end

  def before_render
    @team_scope = params[:team_id].present? && active_path?("/teams/#{params[:team_id]}")

    @team_link_tag = link_to "Manage #{current_team.name}", current_team_home_path, role: "button" if current_team

    # TODO: move this into a "profile" section
    @login_records_link_tag = link_to "Logins", login_records_path, role: active_path?(login_records_path) ? "button" : nil
  end
end
