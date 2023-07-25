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
    add_column :members, :yid, :string, primary_key: true, null: false
    # add_index :members, :yid, unique: true

    execute "ALTER TABLE pictures DROP CONSTRAINT pictures_pkey" # remove the PRIMARY KEY id
    remove_column :pictures, :id, :uuid, default: -> { "gen_random_uuid()" }, null: false
    add_column :pictures, :yid, :string, primary_key: true, null: false
    # add_index :pictures, :yid, unique: true

    execute "ALTER TABLE teams DROP CONSTRAINT teams_pkey" # remove the PRIMARY KEY id
    remove_column :teams, :id, :uuid, default: -> { "gen_random_uuid()" }, null: false
    add_column :teams, :yid, :string, primary_key: true, null: false
    # add_index :teams, :yid, unique: true

    execute "ALTER TABLE users DROP CONSTRAINT users_pkey" # remove the PRIMARY KEY id
    remove_column :users, :id, :uuid, default: -> { "gen_random_uuid()" }, null: false
    add_column :users, :yid, :string, primary_key: true, null: false
    # add_index :users, :yid, unique: true

    change_column :active_storage_attachments, :record_id, :string

    add_column :members, :team_yid, :string, null: false
    add_column :members, :user_yid, :string, null: false
    add_foreign_key :members, :teams, column: :team_yid, primary_key: "yid"
    add_foreign_key :members, :users, column: :user_yid, primary_key: "yid"
    add_index :members, %i[team_yid user_yid], unique: true
    add_index :members, :user_yid
  end

  def down
    remove_index :members, :user_yid
    remove_index :members, %i[team_yid user_yid], unique: true
    remove_foreign_key :members, :teams, column: :team_yid, primary_key: "yid"
    remove_foreign_key :members, :users, column: :user_yid, primary_key: "yid"
    remove_column :members, :team_yid, :string, null: false
    remove_column :members, :user_yid, :string, null: false

    execute "ALTER TABLE members DROP CONSTRAINT members_pkey" # remove the PRIMARY KEY yid
    remove_column :members, :yid, :string, null: false
    add_column :members, :id, :uuid, primary_key: true, null: false, default: -> { "gen_random_uuid()" }
    # add_index :members, :id, unique: true

    execute "ALTER TABLE pictures DROP CONSTRAINT pictures_pkey" # remove the PRIMARY KEY yid
    remove_column :pictures, :yid, :string, null: false
    add_column :pictures, :id, :uuid, primary_key: true, null: false, default: -> { "gen_random_uuid()" }
    # add_index :pictures, :id, unique: true

    execute "ALTER TABLE teams DROP CONSTRAINT teams_pkey" # remove the PRIMARY KEY yid
    remove_column :teams, :yid, :string, null: false
    add_column :teams, :id, :uuid, primary_key: true, null: false, default: -> { "gen_random_uuid()" }
    # add_index :teams, :id, unique: true

    execute "ALTER TABLE users DROP CONSTRAINT users_pkey" # remove the PRIMARY KEY yid
    remove_column :users, :yid, :string, null: false
    add_column :users, :id, :uuid, primary_key: true, null: false, default: -> { "gen_random_uuid()" }
    # add_index :users, :id, unique: true

    change_column :active_storage_attachments, :record_id, :uuid, using: "record_id::uuid"

    add_column :members, :team_id, :uuid, null: false
    add_column :members, :user_id, :uuid, null: false
    add_foreign_key :members, :teams, column: :team_id, primary_key: "id"
    add_foreign_key :members, :users, column: :user_id, primary_key: "id"
  end
end
