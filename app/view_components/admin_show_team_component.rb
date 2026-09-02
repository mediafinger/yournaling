# frozen_string_literal: true

class AdminShowTeamComponent < ApplicationComponent
  def initialize(team:)
    @team = team
  end

  attr_reader :team
end
