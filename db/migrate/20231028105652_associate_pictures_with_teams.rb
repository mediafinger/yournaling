class AssociatePicturesWithTeams < ActiveRecord::Migration[7.1]
  def change
    add_column :pictures, :team_id, :string, null: false
    # adds a foreign_key on pictures.team_id referencing teams.id:
    add_foreign_key :pictures, :teams, column: :team_id
    add_index :pictures, %i[team_id]
  end
end
