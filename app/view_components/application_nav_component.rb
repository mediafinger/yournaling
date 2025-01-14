class ApplicationNavComponent < ApplicationComponent
  slim_template <<~SLIM
    - if !@admin_scope
      - if current_user&.admin?
        ul
          li
            = link_to "Go to Admin Area", "/admin"

    - if !@current_team_scope
      - if current_team.present?
        = link_to "Go to Current Team", current_team_home_path

    - if @admin_scope
      > admin_scope

    - elsif @team_scope
      > team_scope
      = render ApplicationNavLinksComponent.new(link_sections:  %w[memories members], scope: "team", id: { team_id: params[:team_id] })

    - elsif @current_team_scope
      > current_team_scope
      ul
        li
          = link_to "Search", current_team_new_search_path
      = render ApplicationNavLinksComponent.new(link_sections:  %w[memories locations pictures thoughts weblinks members], scope: "current_team")
      = render ApplicationNavActionsComponent.new(actions_for: %w[memories locations pictures thoughts weblinks members], scope: "current_team")

    - else
      > no_scope

    = render ApplicationNavLinksComponent.new(link_sections: %w[teams])

    - if current_user.persisted?
      = @login_records_link_tag

      = render TeamSwitcherComponent.new
  SLIM

  def initialize(params: {})
    @params = params
  end

  def before_render
    @admin_scope = active_path?("/admin")
    @current_team_scope = active_path?("/current_team")
    @team_scope = params[:team_id].present? && active_path?("/teams/#{params[:team_id]}")

    # TODO: move this into a "profile" section
    @login_records_link_tag = link_to "Logins", login_records_path, role: active_path?(login_records_path) ? "button" : nil
  end
end
