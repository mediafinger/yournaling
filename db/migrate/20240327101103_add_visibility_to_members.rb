class AddVisibilityToMembers < ActiveRecord::Migration[7.1]
  def change
    add_column :members, :visibility, :enum, enum_type: :content_visibility, default: "published", null: false
  end
end
