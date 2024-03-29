module TeamScope
  extend ActiveSupport::Concern

  def self.included(base)
    base.send :helper_method, :current_team, :current_member if base.respond_to? :helper_method
  end

  def switch_current_team(team_yid)
    raise ActiveRecord::RecordNotFound.new("User not persisted", current_user, :yid) unless current_user.persisted?

    team = current_user.teams.find(team_yid)

    session[:team_yid] = team.yid
    @current_team = team
    @current_member = current_user.memberships.find_by!(team:)
    initialize_request_context # to refresh the Current objects directly

    current_team
  end

  def go_solo
    session[:team_yid] = nil
    @current_team = nil
    @current_member = nil
    initialize_request_context # to refresh the Current objects directly

    true
  end

  private

  def current_team
    @current_team ||= current_user.teams.find_by(yid: session[:team_yid]) if session[:team_yid]
  end

  def current_member
    @current_member ||= current_user.memberships.find_by!(team: current_team) if current_team
  end
end
