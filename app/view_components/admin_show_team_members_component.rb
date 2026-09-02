# frozen_string_literal: true

class AdminShowTeamMembersComponent < ApplicationComponent
  def initialize(team:)
    @team = team
  end

  def members
    @members ||= @team.members.includes(:user)
  end
end
