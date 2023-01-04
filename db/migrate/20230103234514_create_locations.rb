class CreateLocations < ActiveRecord::Migration[7.0]
  def change
    create_table :locations, id: :uuid do |t|
      t.text :address
      t.decimal :lat
      t.decimal :long
      t.string :name
      t.text :link

      t.timestamps
    end
  end
end
