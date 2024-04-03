class AdminShowUserTeamsComponent < ApplicationComponent
  erb_template <<-ERB
    <p>
      <strong>Teams:</strong>
      <ul>
        <% @user.teams.each do |team| %>
          <li>
            <%= @team_links[team.yid] %>
            <i>(<%= team.yid %>)</i>
            [<%= @member_links[team.yid] %>]
          </li>
        <% end %>
      </ul>
    </p>
  ERB

  def initialize(user:)
    @user = user
  end

  def before_render
    @team_links = @user.teams.each_with_object({}) do |team, hash|
      hash[team.yid] = link_to(team.name, admin_team_path(team))
    end

    @member_links = @user.teams.each_with_object({}) do |team, hash|
      member = @user.memberships.find_by(team:)
      roles = member.roles.join(", ")
      hash[team.yid] = link_to(roles, admin_member_path(member))
    end
  end
end
