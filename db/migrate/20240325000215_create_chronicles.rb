class CreateChronicles < ActiveRecord::Migration[7.1]
  StrongMigrations.disable_check(:add_foreign_key) # as tables are empty

  def change
    create_table :chronicles, primary_key: "yid", id: :string do |t|
      t.string :name, null: false
      t.text :notes, null: false
      t.string :team_yid, null: false
      t.enum :visibility, enum_type: :content_visibility, default: "draft", null: false

      t.timestamps
    end

    create_table :insights, primary_key: "yid", id: :string do |t|
      t.string :team_yid, null: false
      t.string :chronicle_yid, null: false
      t.string :location_yid
      t.string :picture_yid
      t.string :weblink_yid

      t.timestamps
    end

    add_index :chronicles, %i[team_yid name], unique: true

    add_foreign_key :chronicles, :teams, column: :team_yid, primary_key: :yid

    add_index :insights, %i[team_yid chronicle_yid]

    add_foreign_key :insights, :chronicles, column: :chronicle_yid, primary_key: :yid
    add_foreign_key :insights, :locations, column: :location_yid, primary_key: :yid
    add_foreign_key :insights, :pictures, column: :picture_yid, primary_key: :yid
    add_foreign_key :insights, :teams, column: :team_yid, primary_key: :yid
    add_foreign_key :insights, :weblinks, column: :weblink_yid, primary_key: :yid
  end
end
