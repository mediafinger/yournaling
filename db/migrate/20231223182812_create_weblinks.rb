class CreateWeblinks < ActiveRecord::Migration[7.1]
  def change
    create_table :weblinks, id: :string do |t|
      t.string :team_id, null: false
      t.text :url, null: false
      t.string :name, null: false
      t.text :description
      t.json :preview_snippet, default: {}

      t.timestamps
    end

    add_index :weblinks, %i[team_id url], unique: true

    add_foreign_key :weblinks, :teams, column: :team_id
  end
end
