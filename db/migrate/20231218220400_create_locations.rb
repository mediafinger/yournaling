class CreateLocations < ActiveRecord::Migration[7.1]
  StrongMigrations.disable_check(:add_foreign_key) # as tables are empty

  def change
    create_table :locations, primary_key: "yid", id: :string do |t|
      t.string :team_yid, null: false
      t.json :address, default: {}
      t.decimal :lat
      t.decimal :long
      t.string :name, null: false
      t.text :url, null: false

      t.timestamps
    end

    add_index :locations, %i[team_yid name], unique: true

    add_foreign_key :locations, :teams, column: :team_yid, primary_key: :yid
  end
end
