class CreateTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :teams, id: :uuid do |t|
      t.string :name, null: false
      t.jsonb :preferences, null: false, default: {}

      t.timestamps

      t.index :name, unique: true
    end
  end
end
