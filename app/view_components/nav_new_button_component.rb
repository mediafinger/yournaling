# frozen_string_literal: true

# The "+ New" nav control. Emits a bare <li> for a Yui::Navbar group, wrapping
# a Yui::Menu (or a plain CTA nav item when there is only one target).
class NavNewButtonComponent < ApplicationComponent
  MENUS = {
    manage: [
      ["Memory", :new_current_team_memory_path], ["Chronicle", :new_current_team_chronicle_path],
      ["Picture", :new_current_team_picture_path], ["Thought", :new_current_team_thought_path],
      ["Location", :new_current_team_location_path], ["Weblink", :new_current_team_weblink_path]
    ],
    admin: [
      ["Memory", :new_admin_memory_path], ["Chronicle", :new_admin_chronicle_path],
      ["Picture", :new_admin_picture_path], ["Location", :new_admin_location_path],
      ["Thought", :new_admin_thought_path], ["Weblink", :new_admin_weblink_path],
      ["Team", :new_admin_team_path], ["User", :new_admin_user_path], ["Member", :new_admin_member_path]
    ],
  }.freeze

  def initialize(mode: :browse)
    @mode = mode.to_sym
  end

  attr_reader :mode

  # [[label, path], …] for the current mode's dropdown, or nil when "+ New" is a
  # plain link (browse mode, no team).
  def menu_items
    case mode
    when :manage
      items = MENUS[:manage].dup
      items << ["Member", :new_current_team_member_path] if can_manage_members?
      items
    when :admin
      MENUS[:admin]
    when :browse
      return nil unless current_user&.persisted? && current_team.present?

      [["Memory", :new_current_team_memory_path], ["Chronicle", :new_current_team_chronicle_path]]
    end
  end

  # Where "+ New" links to when it is a plain link (browse mode only).
  def plain_link_path
    return login_path unless current_user&.persisted?

    current_team.blank? ? switch_current_teams_path : nil
  end

  private

  def can_manage_members?
    current_member&.roles.to_a.intersect?(%w[owner manager])
  end
end
