class CreateWeblinks < ActiveRecord::Migration[7.1]
  def change
    create_table :weblinks, id: :uuid do |t|
      t.text :url
      t.string :name
      t.text :description
      t.json :preview_snippet

      t.timestamps
    end
  end
end
