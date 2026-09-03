# frozen_string_literal: true

class CreateStories < ActiveRecord::Migration[8.1]
  def change
    create_table :stories, id: :string do |t|
      t.references :team, type: :string, null: false, index: false, foreign_key: true
      t.string :name, null: false
      t.text :content, null: false
      t.date :date
      t.enum :visibility, enum_type: :content_visibility, default: "draft", null: false

      t.timestamps
    end

    add_index :stories, %i[team_id date]
    add_index :stories, %i[team_id name]
  end
end
