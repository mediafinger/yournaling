# frozen_string_literal: true

class AddStoriesToTeamArtefactsView < ActiveRecord::Migration[8.1]
  def change
    update_view :team_artefacts, version: 2, revert_to_version: 1
  end
end
