class CreateLocations < ActiveRecord::Migration[7.0]
  def change
    create_table :locations, id: :uuid do |t|
      t.text :address
      t.decimal :lat, precision: 12, scale: 9
      t.decimal :long, precision: 12, scale: 9
      t.string :name
      t.text :link

      t.timestamps
    end
  end
end
