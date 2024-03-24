class ApplicationNavComponent < ApplicationComponent
  erb_template <<-ERB
    <%= render ApplicationNavLinksComponent.new(link_sections: @sections) %>

    <%= render TeamSwitcherComponent.new %>

    <%= link_to "Search", new_search_path %>

    <%= render ApplicationNavActionsComponent.new(actions_for: @sections) %>
  ERB

  def initialize
    @sections = %w[pictures locations weblinks members]
  end
end
