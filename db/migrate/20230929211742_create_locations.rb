class CreateLocations < ActiveRecord::Migration[7.0]
  def change
    create_table :locations, primary_key: "yid", id: :string, force: :cascade do |t|
      t.text :address
      t.string :country_code, null: false
      t.decimal :lat, precision: 12, scale: 9
      t.decimal :long, precision: 12, scale: 9
      t.string :name
      t.text :link

      t.timestamps

      t.index :country_code
      t.index %i[lat long]
    end
  end
end
