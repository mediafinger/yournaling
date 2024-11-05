class AppCurrentTeamController < ApplicationController
  before_action :authenticate_member!

  # TODO: layout "current_team_area" ?!

  private

  def current_team_scope(relation)
    relation.where(team: current_team)
  end

  def create_with_history(record:, history_params: { team: current_team, user: current_user })
    ApplicationRecordYidEnabled.create_with_history(record:, history_params:)
  end

  def update_with_history(record:, history_params: { team: current_team, user: current_user })
    ApplicationRecordYidEnabled.update_with_history(record:, history_params:)
  end

  def destroy_with_history(record:, history_params: { team: current_team, user: current_user })
    ApplicationRecordYidEnabled.destroy_with_history(record:, history_params:)
  end

  def authenticate_member!
    return true if current_member.present?

    redirect_to root_url, alert: I18n.t("helpers.controller.unauthorized")
  end
end
