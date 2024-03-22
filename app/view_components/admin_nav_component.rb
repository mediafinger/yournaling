class AdminNavComponent < ApplicationComponent
  erb_template <<-ERB
    <%= render ApplicationNavLinksComponent.new(link_sections: @sections, scope: "admin") %>

    <%= render ApplicationNavActionsComponent.new(actions_for: @sections, scope: "admin") %>
  ERB

  def initialize
    @sections = %w[users teams members pictures weblinks locations]
  end
end
