class AdminShowTeamMembersComponent < ApplicationComponent
  erb_template <<-ERB
    <p>
      <strong>Members:</strong>
      <ul>
        <% @team.members.each do |member| %>
          <li>
            <%= @user_links[member.yid] %>
            <i>(<%= member.yid %>)</i>
            [<%= @member_links[member.yid] %>]
          </li>
        <% end %>
      </ul>
    </p>
  ERB

  def initialize(team:)
    @team = team
  end

  def before_render
    @user_links = @team.members.each_with_object({}) do |member, hash|
      hash[member.yid] = link_to(member.user.name, admin_user_url(member.user))
    end

    @member_links = @team.members.each_with_object({}) do |member, hash|
      roles = member.roles.join(", ")
      hash[member.yid] = link_to(roles, admin_member_url(member))
    end
  end
end
