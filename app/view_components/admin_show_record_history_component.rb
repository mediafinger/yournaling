class AdminShowRecordHistoryComponent < ApplicationComponent
  erb_template <<~ERB
    <article id="<%=dom_id(@record_history)%>">
      <p>
        <strong>
          Event:
          <%= @record_history.event %>
        </strong>
        <%= @record_history.created_at.to_formatted_s(:db) %>
        <% if @record_history.done_by_admin? %>
          <strong>done by Admin</strong>
        <% end %>
      </p>

      <p>
        <strong>Record:</strong>
        <%= @record_link %>
        <i>(<%= @record_history.record_yid %>)</i>
      </p>

      <p>
        <strong>User:</strong>
        <% if @user.present? %>
          <%= @user_link %>
        <% end %>
        <i>(<%= @record_history.user_yid %>)</i>
      </p>

      <p>
        <strong>Team:</strong>
        <% if @record_history.team_yid == "admin" %>
          admin
        <% elsif @record_history.team_yid == "none" %>
          none
        <% else %>
          <% if @team.present? %>
            <%= @team_link %>
          <% end %>
          <i>(<%= @record_history.team_yid %>)</i>
        <% end %>
      </p>

      <p>
        <strong>YID:</strong>
        <%= @record_history.id %>
      </p>
    </article>
  ERB

  def initialize(record_history:)
    @record_history = record_history

    @record = ApplicationRecordYidEnabled.fynd(record_history.record_yid)
    @user = User.find_by(yid: record_history.user_yid)
    @team = Team.find_by(yid: record_history.team_yid)
  end

  def before_render
    @record_link =
      if @record.present?
        link_to(@record.class.name, send(:"admin_#{@record.class.name.tableize.singularize}_path", @record))
      else
        ApplicationRecordYidEnabled.yid_code_models[@record_history.record_yid.split("_").first].name
      end

    @user_link = link_to(@user.name, admin_user_path(@user)) if @user
    @team_link = link_to(@team.name, admin_team_path(@team)) if @team
  end
end
