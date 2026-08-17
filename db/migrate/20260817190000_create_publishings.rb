# frozen_string_literal: true

class CreatePublishings < ActiveRecord::Migration[8.1]
  def change
    create_table :publishings, id: :string do |t|
      t.references :team, type: :string, null: false, foreign_key: true, index: false
      t.string :post_type, null: false
      t.string :post_id, null: false
      t.datetime :first_published_at, null: false
      t.datetime :republished_at, null: false
      t.integer :published_count, default: 1, null: false
      t.enum :visibility, enum_type: :content_visibility, null: false

      t.timestamps
    end

    add_index :publishings, %i[post_type post_id], unique: true
    add_index :publishings, %i[team_id republished_at]
    add_index :publishings, %i[visibility republished_at]
    add_index :publishings, :republished_at

    reversible do |dir|
      dir.up do
        now = Time.current.utc
        [Chronicle, Memory].each do |klass|
          klass.reset_column_information
          klass.where(visibility: "published").find_each do |record|
            created_at = record.created_at || now
            Publishing.find_or_create_by!(post_type: klass.name, post_id: record.id) do |pub|
              pub.team_id = record.team_id
              pub.first_published_at = created_at
              pub.republished_at = record.updated_at || created_at
              pub.published_count = 1
              pub.visibility = "published"
            end
          end
        end
      end
    end
  end
end
