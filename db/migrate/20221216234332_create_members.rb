class CreateMembers < ActiveRecord::Migration[7.0]
  def change
    create_table :members, id: :uuid do |t|
      t.references :user, foreign_key: true, type: :uuid, null: false, index: false
      t.references :team, foreign_key: true, type: :uuid, null: false, index: false
      t.text :roles, array: true, default: [], null: false

      t.timestamps

      t.index %i[team_id user_id], unique: true
    end
  end
end
