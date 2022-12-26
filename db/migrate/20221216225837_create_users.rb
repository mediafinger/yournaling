class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users, id: :uuid do |t|
      t.string :name, null: false
      t.string :nickname
      t.string :email, null: false
      t.string :password_digest, null: false
      t.text :temp_auth_token # for email confirmation or password reset, roll your own expiration logic, e.g. JWT
      t.jsonb :preferences, null: false, default: {}

      t.timestamps

      t.index :email, unique: true
      t.index :nickname, unique: true
      t.index :temp_auth_token, unique: true
    end
  end
end
