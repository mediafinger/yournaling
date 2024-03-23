class AddGeocodedAddressToLocations < ActiveRecord::Migration[7.1]
  def up
    safety_assured { change_column :locations, :address, :string, null: true, default: nil }
    add_column :locations, :geocoded_address, :jsonb, null: false, default: {}
    change_column_null :locations, :url, true
  end

  def down
    safety_assured { change_column :locations, :address, :json, null: false, default: {} }
    add_column :locations, :geocoded_address, :jsonb, null: false, default: {}
    change_column_null :locations, :url, false
  end
end
