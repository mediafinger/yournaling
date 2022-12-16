class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users, id: :uuid do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :temp_auth_token # for email confirmation or password reset, roll your own expiration logic
      t.jsonb :preferences, null: false, default: {}

      t.timestamps

      t.index :email, unique: true
    end
  end
end
