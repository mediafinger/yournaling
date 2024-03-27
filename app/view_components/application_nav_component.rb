class ApplicationNavComponent < ApplicationComponent
  erb_template <<-ERB
    <% if current_user&.admin? %>
    <ul>
      <li><%= link_to "Go to Admin Area", "/admin" %></li>
    </ul>
    <% end %>

    <%= render ApplicationNavLinksComponent.new(link_sections:  %w[memories members], scope: "teams") %>

    |

    <%= render ApplicationNavLinksComponent.new(link_sections: @sections) %>

    <%= render TeamSwitcherComponent.new %>

    <% if current_team.present? %>
    <ul>
      <li><%= link_to "Search", new_search_path %></li>
    </ul>
    <% end %>

    <%= render ApplicationNavActionsComponent.new(actions_for: @sections) %>
  ERB

  def initialize
    @sections = %w[memories pictures locations weblinks members]
  end
end
