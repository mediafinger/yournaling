# frozen_string_literal: true

# Right-hand nav group: admin-area link, team switcher, account + logout.
# Emits bare <li>s for a Yui::Navbar group (no wrapping <ul>).
class TeamSwitcherAndSessionsComponent < ApplicationComponent
  def initialize(mode: :browse)
    @mode = mode.to_sym
  end

  attr_reader :mode

  def show_admin_link?
    mode != :admin && current_user&.admin?
  end

  def show_switch_team?
    mode != :admin && current_user&.persisted? && current_user.teams.any?
  end

  def signed_in?
    current_user&.persisted?
  end
end
