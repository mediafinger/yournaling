class TeamSwitcherComponent < ApplicationComponent
  slim_template <<~SLIM
    ul
      - if current_user.persisted?
        - if current_user.teams
          li
            = @switch_teams_link_tag
        li
          = @logout_button_tag
      - else
        li
          = @login_link_tag
  SLIM

  def initialize
    # no-op
  end

  def before_render
    @login_link_tag = link_to "Login",
      login_path,
      role: active_path?(login_path) ? "button" : nil

    @logout_button_tag = button_to "Logout #{current_user.name}", logout_path,
      { method: :delete, role: "link", class: "logout" }

    @switch_teams_link_tag = link_to "Switch team",
      switch_current_teams_path,
      role: active_path?(switch_current_teams_path) ? "button" : nil
  end
end
