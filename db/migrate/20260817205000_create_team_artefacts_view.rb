# frozen_string_literal: true

class CreateTeamArtefactsView < ActiveRecord::Migration[8.1]
  def change
    create_view :team_artefacts, version: 1
  end
end
