# frozen_string_literal: true

# Primary nav for the public / default layout.
class ApplicationNavComponent < ApplicationComponent
  def initialize(params: {})
    super()
    @params = params
  end

  # The team whose members link we show (route param wins over current_team).
  def members_target
    params[:team_id].presence || current_team
  end

  def teams_active?
    active_path?(teams_path) && (members_target.blank? || !active_path?(team_members_path(members_target)))
  end
end
