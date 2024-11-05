#
# Destructive Migration - only to be run on empty databases!
#
class AddYidToAllTables < ActiveRecord::Migration[7.0]
  def up
    remove_foreign_key :members, :teams, column: :team_id, primary_key: "id"
    remove_foreign_key :members, :users, column: :user_id, primary_key: "id"
    remove_column :members, :team_id, :uuid, null: false
    remove_column :members, :user_id, :uuid, null: false

    execute "ALTER TABLE members DROP CONSTRAINT members_pkey" # remove the PRIMARY KEY id
    remove_column :members, :id, :uuid, default: -> { "gen_random_uuid()" }, null: false
    add_column :members, :id, :string, primary_key: true, null: false
    # add_index :members, :id, unique: true

    execute "ALTER TABLE pictures DROP CONSTRAINT pictures_pkey" # remove the PRIMARY KEY id
    remove_column :pictures, :id, :uuid, default: -> { "gen_random_uuid()" }, null: false
    add_column :pictures, :id, :string, primary_key: true, null: false
    # add_index :pictures, :id, unique: true

    execute "ALTER TABLE teams DROP CONSTRAINT teams_pkey" # remove the PRIMARY KEY id
    remove_column :teams, :id, :uuid, default: -> { "gen_random_uuid()" }, null: false
    add_column :teams, :id, :string, primary_key: true, null: false
    # add_index :teams, :id, unique: true

    execute "ALTER TABLE users DROP CONSTRAINT users_pkey" # remove the PRIMARY KEY id
    remove_column :users, :id, :uuid, default: -> { "gen_random_uuid()" }, null: false
    add_column :users, :id, :string, primary_key: true, null: false
    # add_index :users, :id, unique: true

    add_column :members, :team_id, :string, null: false
    add_column :members, :user_id, :string, null: false
    add_foreign_key :members, :teams, column: :team_id, primary_key: "id"
    add_foreign_key :members, :users, column: :user_id, primary_key: "id"
    add_index :members, %i[team_id user_id], unique: true
    add_index :members, :user_id
  end

  def down
    remove_index :members, :user_id
    remove_index :members, %i[team_id user_id], unique: true
    remove_foreign_key :members, :teams, column: :team_id, primary_key: "id"
    remove_foreign_key :members, :users, column: :user_id, primary_key: "id"
    remove_column :members, :team_id, :string, null: false
    remove_column :members, :user_id, :string, null: false

    execute "ALTER TABLE members DROP CONSTRAINT members_pkey" # remove the PRIMARY KEY id
    remove_column :members, :id, :string, null: false
    add_column :members, :id, :uuid, primary_key: true, null: false, default: -> { "gen_random_uuid()" }
    # add_index :members, :id, unique: true

    execute "ALTER TABLE pictures DROP CONSTRAINT pictures_pkey" # remove the PRIMARY KEY id
    remove_column :pictures, :id, :string, null: false
    add_column :pictures, :id, :uuid, primary_key: true, null: false, default: -> { "gen_random_uuid()" }
    # add_index :pictures, :id, unique: true

    execute "ALTER TABLE teams DROP CONSTRAINT teams_pkey" # remove the PRIMARY KEY id
    remove_column :teams, :id, :string, null: false
    add_column :teams, :id, :uuid, primary_key: true, null: false, default: -> { "gen_random_uuid()" }
    # add_index :teams, :id, unique: true

    execute "ALTER TABLE users DROP CONSTRAINT users_pkey" # remove the PRIMARY KEY id
    remove_column :users, :id, :string, null: false
    add_column :users, :id, :uuid, primary_key: true, null: false, default: -> { "gen_random_uuid()" }
    # add_index :users, :id, unique: true

    add_column :members, :team_id, :uuid, null: false
    add_column :members, :user_id, :uuid, null: false
    add_foreign_key :members, :teams, column: :team_id, primary_key: "id"
    add_foreign_key :members, :users, column: :user_id, primary_key: "id"
  end
end
