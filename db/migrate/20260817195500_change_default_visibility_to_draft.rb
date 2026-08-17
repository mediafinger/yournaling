# frozen_string_literal: true

class ChangeDefaultVisibilityToDraft < ActiveRecord::Migration[8.1]
  def change
    change_column_default :chronicles, :visibility, from: "internal", to: "draft"
    change_column_default :locations, :visibility, from: "internal", to: "draft"
    change_column_default :pictures, :visibility, from: "internal", to: "draft"
    change_column_default :thoughts, :visibility, from: "internal", to: "draft"
    change_column_default :weblinks, :visibility, from: "internal", to: "draft"
  end
end
