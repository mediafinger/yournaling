class AppTeamsController < ApplicationController
  #
  # TODO: implement finer grained view controls
  # allow paying teams to restrict who can view their content:
  # - everyone (public, includes guest_users)
  # - all current_users (user must be logged in, no google robots allowed)
  # - only current_users that are followers (+ enable teams to approve and manage their followers)
  #
  skip_verify_authorized # allow all current_users and guests to see published records

  helper_method :team

  def team
    Team.urlsafe_find!(params[:team_id]) # TODO: handle /teams/:id endpoints
  rescue ActiveRecord::RecordNotFound => e
    redirect_to root_url, alert: e.message
  end

  private

  def record(relation, id)
    records_scope(relation).urlsafe_find!(id)
  end

  def records_scope(relation)
    relation.where(team:, visibility: :published)
  end
end
