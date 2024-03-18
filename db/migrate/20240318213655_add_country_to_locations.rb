class AddCountryToLocations < ActiveRecord::Migration[7.1]
  def change
    add_column :locations, :description, :string
    add_column :locations, :country_code, :string, null: false
    add_index :locations, :country_code
  end
end
