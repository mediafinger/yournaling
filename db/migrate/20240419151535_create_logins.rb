class CreateLogins < ActiveRecord::Migration[7.1]
  StrongMigrations.disable_check(:add_foreign_key) # as tables are empty

  def change
    create_table :logins, id: :uuid do |t|
      t.string :user_yid, null: false
      t.string :ip_address, null: false
      t.text :user_agent, null: false
      t.string :device_id, null: false

      t.timestamps
    end

    add_foreign_key :logins, :users, column: :user_yid, primary_key: :yid

    add_index :logins, %i[user_yid device_id], unique: true
  end
end
