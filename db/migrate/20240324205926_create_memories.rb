class CreateMemories < ActiveRecord::Migration[7.1]
  def change
    create_enum :content_visibility, %w[draft internal published archived blocked]

    create_table :memories, id: :string do |t|
      t.text :memo, null: false
      t.string :team_id, null: false
      t.string :location_id
      t.string :picture_id
      t.string :weblink_id
      t.enum :visibility, enum_type: :content_visibility, default: "draft", null: false

      t.timestamps
    end

    add_index :memories, %i[team_id]

    add_foreign_key :memories, :locations, column: :location_id
    add_foreign_key :memories, :pictures, column: :picture_id
    add_foreign_key :memories, :teams, column: :team_id
    add_foreign_key :memories, :weblinks, column: :weblink_id
  end
end
