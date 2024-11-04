class AddDateToInsights < ActiveRecord::Migration[8.0]
  def change
    add_column :locations, :date, :date, null: true
    add_column :weblinks, :date, :date, null: true
  end
end
