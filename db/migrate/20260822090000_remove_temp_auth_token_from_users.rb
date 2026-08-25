# frozen_string_literal: true

# The `temp_auth_token` column was scaffolded in the very first users migration as a
# placeholder for "email confirmation or password reset". Both concerns are now solved
# with Rails' stateless `generates_token_for`, so the column has never been read or written.
#
class RemoveTempAuthTokenFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_index :users, :temp_auth_token, unique: true
    remove_column :users, :temp_auth_token, :text
  end
end
