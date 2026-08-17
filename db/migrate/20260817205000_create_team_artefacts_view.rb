# frozen_string_literal: true

class CreateTeamArtefactsView < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      CREATE VIEW team_artefacts AS
      SELECT id AS artefact_id, 'Chronicle' AS artefact_type, team_id, visibility, updated_at, created_at FROM chronicles
      UNION ALL
      SELECT id AS artefact_id, 'Memory' AS artefact_type, team_id, visibility, updated_at, created_at FROM memories
      UNION ALL
      SELECT id AS artefact_id, 'Picture' AS artefact_type, team_id, visibility, updated_at, created_at FROM pictures
      UNION ALL
      SELECT id AS artefact_id, 'Location' AS artefact_type, team_id, visibility, updated_at, created_at FROM locations
      UNION ALL
      SELECT id AS artefact_id, 'Thought' AS artefact_type, team_id, visibility, updated_at, created_at FROM thoughts
      UNION ALL
      SELECT id AS artefact_id, 'Weblink' AS artefact_type, team_id, visibility, updated_at, created_at FROM weblinks
      UNION ALL
      SELECT id AS artefact_id, 'Member' AS artefact_type, team_id, visibility, updated_at, created_at FROM members;
    SQL
  end

  def down
    execute "DROP VIEW IF EXISTS team_artefacts;"
  end
end
