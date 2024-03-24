class AdminNavComponent < ApplicationComponent
  erb_template <<-ERB
    <% if current_user&.admin? %>
    <ul>
      <li><%= link_to "Leave Admin Area", "/" %></li>
    </ul>
    <% end %>

    <%= render ApplicationNavLinksComponent.new(link_sections: @sections, scope: "admin") %>

    <%= render ApplicationNavActionsComponent.new(actions_for: @sections, scope: "admin") %>
  ERB

  def initialize
    @sections = %w[users teams members pictures weblinks locations record_history]
  end
end
