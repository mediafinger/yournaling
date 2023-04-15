class CreateMemories < ActiveRecord::Migration[7.0]
  def change
    create_table :memories, id: :uuid do |t|
      t.date :date
      t.string :note
      t.string :picture_id
      # t.string :location_id # Location Model does not exist yet
      # t.text :tags, array: true, default: [], null: false # not ideal, refactor to Hstore or similar

      t.timestamps

      t.index :date
    end
  end
end

# the name or description is mandatory and
#   either a link or geocoding information have to exist as well
#
#
# SPLIT (GEO) LOCATION from URLS / LINKS ?!
#
class CreateLocations < ActiveRecord::Migration[7.0]
  def change
    create_table :locations, id: :uuid do |t|
      t.string :name, null: false

      t.string :link # to (Google) Maps or any Website

      t.decimal :lat # filled either via geocoding, or set by user
      t.decimal :lng # filled either via geocoding, or set by user

      t.string :address # user input only, used to geocode

      t.string :country # filled either via geocoding, or set by user
      t.string :province # filled either via geocoding, or set by user
      t.string :city # filled either via geocoding, or set by user
      t.string :street # filled either via geocoding, or set by user
      t.string :number # filled either via geocoding, or set by user
      t.string :additional # filled either via geocoding, or set by user

      t.timestamps

      t.index :name
      t.index [:lat, :lng]
      t.index [:country, :province, :city]
    end
  end
end
