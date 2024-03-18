class CreateWeblinks < ActiveRecord::Migration[7.1]
  StrongMigrations.disable_check(:add_foreign_key) # as tables are empty

  def change
    create_table :weblinks, primary_key: "yid", id: :string do |t|
      t.string :team_yid, null: false
      t.text :url, null: false
      t.string :name, null: false
      t.text :description
      t.json :preview_snippet, default: {}

      t.timestamps
    end

    add_index :weblinks, %i[team_yid url], unique: true

    add_foreign_key :weblinks, :teams, column: :team_yid, primary_key: :yid
  end
end
