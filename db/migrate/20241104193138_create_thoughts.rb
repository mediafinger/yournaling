class CreateThoughts < ActiveRecord::Migration[8.0]
  def change
    create_table :thoughts, id: :string do |t|
      t.references :team, type: :string, null: false, index: false, foreign_key: true
      t.text :text, null: false
      t.date :date
      t.virtual :name, type: :string, as: "(((SUBSTRING(text, 0, 60))::text || '...'::text))", stored: true
      t.enum :visibility, enum_type: :content_visibility, default: "internal", null: false

      t.timestamps
    end

    add_index :thoughts, %i[team_id date]

    add_reference :memories, :thought, type: :string, index: false, foreign_key: true
  end
end
