class AdminShowUserTeamsComponent < ApplicationComponent
  slim_template <<~SLIM
    p
      strong Teams:
    ul
      - @user.teams.each do |team|
        li
          = @team_links[team.id]
          i
            > (
            = team.id
            > )
          = @member_links[team.id]
  SLIM

  def initialize(user:)
    @user = user
  end

  def before_render
    @team_links = @user.teams.each_with_object({}) do |team, hash|
      hash[team.id] = link_to(team.name, admin_team_path(team))
    end

    @member_links = @user.teams.each_with_object({}) do |team, hash|
      member = @user.memberships.find_by(team:)
      roles = member.roles.join(", ")
      hash[team.id] = link_to(roles, admin_member_path(member))
    end
  end
end
