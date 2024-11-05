class AdminShowTeamMembersComponent < ApplicationComponent
  slim_template <<~SLIM
    p
      strong Members:
      ul
        - @team.members.each do |member|
          li
            = @user_links[member.id]
            i
              > (
              = member.id
              > )

            > (
            = @member_links[member.id]
            > )
  SLIM

  def initialize(team:)
    @team = team
  end

  def before_render
    @user_links = @team.members.each_with_object({}) do |member, hash|
      hash[member.id] = link_to(member.user.name, admin_user_path(member.user))
    end

    @member_links = @team.members.each_with_object({}) do |member, hash|
      roles = member.roles.join(", ")
      hash[member.id] = link_to(roles, admin_member_path(member))
    end
  end
end
