class AssociatePicturesWithTeams < ActiveRecord::Migration[7.1]
  def change
    add_column :pictures, :team_yid, :string, null: false
    # adds a foreign_key on pictures.team_yid referencing teams.yid:
    add_foreign_key :pictures, :teams, column: :team_yid, primary_key: "yid"
    add_index :pictures, %i[team_yid]
  end
end
