class ApplicationNavComponent < ApplicationComponent
  erb_template <<-ERB
    <%= render ApplicationNavLinksComponent.new(link_sections: @sections) %>

    <%= render TeamSwitcherComponent.new %>

    <%= render ApplicationNavActionsComponent.new(actions_for: @sections) %>
  ERB

  def initialize
    @sections = %w[pictures locations weblinks teams users members]
  end
end
