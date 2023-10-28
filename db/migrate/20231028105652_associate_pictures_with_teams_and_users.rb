class AssociatePicturesWithTeamsAndUsers < ActiveRecord::Migration[7.1]
  StrongMigrations.safe_by_default = true # no production usage yet

  def change
    add_column :pictures, :team_yid, :string, null: false
    # adds a foreign_key on pictures.team_yid referencing teams.yid:
    add_foreign_key :pictures, :teams, column: :team_yid, primary_key: "yid"
    add_index :pictures, %i[team_yid]

    add_column :pictures, :created_by, :string, null: true
    # adds a foreign_key on pictures.created_by referencing users.yid:
    add_foreign_key :pictures, :users, column: :created_by, primary_key: "yid"
    add_index :pictures, %i[created_by]

    add_column :pictures, :updated_by, :string, null: true
    # adds a foreign_key on pictures.updated_by referencing users.yid:
    add_foreign_key :pictures, :users, column: :updated_by, primary_key: "yid"
    add_index :pictures, %i[updated_by]
  end
end
