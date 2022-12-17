class CreateMembers < ActiveRecord::Migration[7.0]
  def change
    create_table :members, id: :uuid do |t|
      t.references :user, foreign_key: true, type: :uuid, null: false
      t.references :team, foreign_key: true, type: :uuid, null: false
      t.text :roles, array: true, default: [], null: false

      t.timestamps
    end
  end
end
