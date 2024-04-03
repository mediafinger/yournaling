class AdminShowTeamComponent < ApplicationComponent
  erb_template <<-ERB
    <p>
      <strong>Team:</strong>
      <%= @team_link_tag %>
      <i>(<%= @team.yid %>)</i>
    </p>
  ERB

  def initialize(team:)
    @team = team
  end

  def before_render
    @team_link_tag = link_to(@team.name, admin_team_path(@team))
  end
end
