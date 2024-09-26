class CreateChronicles < ActiveRecord::Migration[7.1]
  StrongMigrations.disable_check(:add_foreign_key) # as tables are empty

  def change
    create_table :chronicles, primary_key: "yid", id: :string do |t|
      t.string :name, null: false
      t.text :notes, null: false
      t.string :team_yid, null: false
      t.string :locations_order, array: true, null: false, default: []
      t.string :pictures_order, array: true, null: false, default: []
      t.string :weblinks_order, array: true, null: false, default: []
      t.enum :visibility, enum_type: :content_visibility, default: "draft", null: false

      t.timestamps
    end

    create_table :chronicle_locations, primary_key: "yid", id: :string do |t|
      t.string :team_yid, null: false
      t.string :chronicle_yid, null: false
      t.string :location_yid, null: false

      t.timestamps
    end

    create_table :chronicle_pictures, primary_key: "yid", id: :string do |t|
      t.string :team_yid, null: false
      t.string :chronicle_yid, null: false
      t.string :picture_yid, null: false

      t.timestamps
    end

    create_table :chronicle_weblinks, primary_key: "yid", id: :string do |t|
      t.string :team_yid, null: false
      t.string :chronicle_yid, null: false
      t.string :weblink_yid, null: false

      t.timestamps
    end

    add_index :chronicles, %i[team_yid name], unique: true
    add_index :chronicle_locations, %i[team_yid chronicle_yid location_yid], unique: true
    add_index :chronicle_pictures, %i[team_yid chronicle_yid picture_yid], unique: true
    add_index :chronicle_weblinks, %i[team_yid chronicle_yid weblink_yid], unique: true

    add_foreign_key :chronicles, :teams, column: :team_yid, primary_key: :yid

    add_foreign_key :chronicle_locations, :teams, column: :team_yid, primary_key: :yid
    add_foreign_key :chronicle_locations, :chronicles, column: :chronicle_yid, primary_key: :yid
    add_foreign_key :chronicle_locations, :locations, column: :location_yid, primary_key: :yid

    add_foreign_key :chronicle_pictures, :teams, column: :team_yid, primary_key: :yid
    add_foreign_key :chronicle_pictures, :chronicles, column: :chronicle_yid, primary_key: :yid
    add_foreign_key :chronicle_pictures, :pictures, column: :picture_yid, primary_key: :yid

    add_foreign_key :chronicle_weblinks, :teams, column: :team_yid, primary_key: :yid
    add_foreign_key :chronicle_weblinks, :chronicles, column: :chronicle_yid, primary_key: :yid
    add_foreign_key :chronicle_weblinks, :weblinks, column: :weblink_yid, primary_key: :yid
  end
end
