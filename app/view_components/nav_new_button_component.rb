# frozen_string_literal: true

class NavNewButtonComponent < ApplicationComponent
  slim_template <<~SLIM
    - if @mode == :browse
      - if !current_user&.persisted?
        li
          = link_to "+ New", login_path, role: "button"
      - elsif current_team.blank?
        li
          = link_to "+ New", switch_current_teams_path, role: "button"
      - else
        li
          details.dropdown
            summary role="button" + New
            ul
              li
                = link_to "Memory", new_current_team_memory_path
              li
                = link_to "Chronicle", new_current_team_chronicle_path

    - elsif @mode == :manage
      li
        details.dropdown
          summary role="button" + New
          ul
            li
              = link_to "Memory", new_current_team_memory_path
            li
              = link_to "Chronicle", new_current_team_chronicle_path
            li
              = link_to "Picture", new_current_team_picture_path
            li
              = link_to "Thought", new_current_team_thought_path
            li
              = link_to "Location", new_current_team_location_path
            li
              = link_to "Weblink", new_current_team_weblink_path
            - if can_manage_members?
              li
                = link_to "Member", new_current_team_member_path

    - elsif @mode == :admin
      li
        details.dropdown
          summary role="button" + New
          ul
            li
              = link_to "Memory", new_admin_memory_path
            li
              = link_to "Chronicle", new_admin_chronicle_path
            li
              = link_to "Picture", new_admin_picture_path
            li
              = link_to "Location", new_admin_location_path
            li
              = link_to "Thought", new_admin_thought_path
            li
              = link_to "Weblink", new_admin_weblink_path
            li
              = link_to "Team", new_admin_team_path
            li
              = link_to "User", new_admin_user_path
            li
              = link_to "Member", new_admin_member_path
  SLIM

  def initialize(mode: :browse)
    @mode = mode.to_sym
  end

  private

  def can_manage_members?
    current_member&.roles&.include?("owner") || current_member&.roles&.include?("manager")
  end
end
