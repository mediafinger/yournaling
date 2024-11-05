class CreateLogins < ActiveRecord::Migration[7.1]
  def change
    create_table :logins, id: :uuid do |t|
      t.string :user_id, null: false
      t.string :ip_address, null: false
      t.text :user_agent, null: false
      t.string :device_id, null: false

      t.timestamps
    end

    add_foreign_key :logins, :users, column: :user_id

    add_index :logins, %i[user_id device_id], unique: true
  end
end
