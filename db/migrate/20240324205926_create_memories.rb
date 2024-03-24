class CreateMemories < ActiveRecord::Migration[7.1]
  StrongMigrations.disable_check(:add_foreign_key) # as tables are empty

  def change
    create_enum :content_visibility, %w[draft internal published archived blocked]

    create_table :memories, primary_key: "yid", id: :string do |t|
      t.text :memo, null: false
      t.string :team_yid, null: false
      t.string :location_yid
      t.string :picture_yid
      t.string :weblink_yid
      t.enum :visibility, enum_type: :content_visibility, default: "draft", null: false

      t.timestamps
    end

    add_index :memories, %i[team_yid]

    add_foreign_key :memories, :locations, column: :location_yid, primary_key: :yid
    add_foreign_key :memories, :pictures, column: :picture_yid, primary_key: :yid
    add_foreign_key :memories, :teams, column: :team_yid, primary_key: :yid
    add_foreign_key :memories, :weblinks, column: :weblink_yid, primary_key: :yid
  end
end
