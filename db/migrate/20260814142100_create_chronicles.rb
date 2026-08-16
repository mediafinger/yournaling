# frozen_string_literal: true

class CreateChronicles < ActiveRecord::Migration[8.1]
  def change
    create_table :chronicles, id: :string do |t|
      t.references :team, type: :string, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.text :notice, null: false
      t.date :start_date, null: false
      t.date :end_date
      t.enum :visibility, enum_type: :content_visibility, default: "internal", null: false

      t.timestamps
    end

    add_index :chronicles, %i[team_id name], unique: true
    add_index :chronicles, %i[team_id start_date]

    create_table :chronicle_entries, id: :string do |t|
      t.references :team, type: :string, null: false, foreign_key: true
      t.references :chronicle, type: :string, null: false, foreign_key: true, index: false
      t.string :entry_type, null: false
      t.string :entry_id, null: false
      t.integer :position, null: false

      t.timestamps
    end

    add_index :chronicle_entries, %i[chronicle_id position], unique: true
    add_index :chronicle_entries, %i[chronicle_id entry_type]
    add_index :chronicle_entries, :entry_id
  end
end
