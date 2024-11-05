class CreateLocations < ActiveRecord::Migration[7.1]
  def change
    create_table :locations, id: :string do |t|
      t.string :team_id, null: false
      t.json :address, default: {}
      t.decimal :lat
      t.decimal :long
      t.string :name, null: false
      t.text :url, null: false

      t.timestamps
    end

    add_index :locations, %i[team_id name], unique: true

    add_foreign_key :locations, :teams, column: :team_id
  end
end
