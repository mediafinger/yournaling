class AdminNavComponent < ApplicationComponent
  slim_template <<~SLIM
    - if current_user&.admin?
      ul
        li
          = link_to "Leave Admin Area", "/"

    = render ApplicationNavLinksComponent.new(link_sections: @sections, scope: "admin")
    = render ApplicationNavActionsComponent.new(actions_for: @sections, scope: "admin")
  SLIM

  def initialize
    @sections = %w[users teams members pictures thoughts weblinks locations record_events]
  end
end
