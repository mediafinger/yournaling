class CreateThoughts < ActiveRecord::Migration[8.0]
  def change


    create_table :thoughts, primary_key: "yid", id: :string do |t|
      t.string :team_yid, null: false
      t.text :text, null: false
      t.date :date
      t.virtual :name, type: :string,
        as: "(((SUBSTRING(text, 0, 60))::text || '... '::text) || (DATE_TO_TEXT(date))::text)",
        stored: true
      t.enum :visibility, enum_type: :content_visibility, default: "internal", null: false

      t.timestamps
    end

    add_index :thoughts, %i[team_yid date]
    add_foreign_key :thoughts, :teams, column: :team_yid, primary_key: :yid

    add_column :memories, :thought_yid, :string
    add_foreign_key :memories, :thoughts, column: :thought_yid, primary_key: :yid
  end
end
