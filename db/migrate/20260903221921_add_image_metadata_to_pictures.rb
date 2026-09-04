# frozen_string_literal: true

# Columns populated from the uploaded image's EXIF data and pixel geometry
# (see Images::MetadataExtractor). The stored file itself is stripped of EXIF,
# so these columns are the only record of when/where a photo was taken.
class AddImageMetadataToPictures < ActiveRecord::Migration[8.1]
  def change
    change_table :pictures, bulk: true do |t|
      t.datetime :taken_at
      t.decimal  :latitude,  precision: 10, scale: 6
      t.decimal  :longitude, precision: 10, scale: 6
      t.decimal  :altitude,  precision: 8,  scale: 2
      t.string   :camera_make
      t.string   :camera_model
      t.integer  :image_width
      t.integer  :image_height
      t.bigint   :original_byte_size
      t.string   :original_content_type
      t.boolean  :exif_stripped, null: false, default: true
    end

    # [team_id, taken_at] also serves the plain team_id lookups the old
    # single-column index covered, so replace it rather than keep both.
    add_index :pictures, %i[team_id taken_at]
    remove_index :pictures, :team_id, name: "index_pictures_on_team_id"
    add_index :pictures, %i[latitude longitude]
  end
end
