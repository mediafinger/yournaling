# frozen_string_literal: true

class AdminShowUserTeamsComponent < ApplicationComponent
  def initialize(user:)
    @user = user
  end

  attr_reader :user

  def membership_for(team)
    user.memberships.find_by(team:)
  end
end
