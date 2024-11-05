class AdminShowTeamComponent < ApplicationComponent
  slim_template <<~SLIM
    p
      strong Team:
      = @team_link_tag
      i
        > (
        = @team.yid
        > )
  SLIM

  def initialize(team:)
    @team = team
  end

  def before_render
    @team_link_tag = link_to(@team.name, admin_team_path(@team))
  end
end
