class AddVisibilityToInsights < ActiveRecord::Migration[7.1]
  def change
    add_column :locations, :visibility, :enum, enum_type: :content_visibility, default: "internal", null: false
    add_column :pictures, :visibility, :enum, enum_type: :content_visibility, default: "internal", null: false
    add_column :weblinks, :visibility, :enum, enum_type: :content_visibility, default: "internal", null: false
  end
end
