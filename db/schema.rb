# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2024_11_04_192139) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "content_visibility", ["draft", "internal", "published", "archived", "blocked"]

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "locations", primary_key: "yid", id: :string, force: :cascade do |t|
    t.string "address"
    t.string "country_code", null: false
    t.datetime "created_at", null: false
    t.date "date"
    t.string "description"
    t.jsonb "geocoded_address", default: {}, null: false
    t.decimal "lat"
    t.decimal "long"
    t.string "name", null: false
    t.string "team_yid", null: false
    t.datetime "updated_at", null: false
    t.text "url"
    t.enum "visibility", default: "internal", null: false, enum_type: "content_visibility"
    t.index ["country_code"], name: "index_locations_on_country_code"
    t.index ["team_yid", "name"], name: "index_locations_on_team_yid_and_name", unique: true
  end

  create_table "logins", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "device_id", null: false
    t.string "ip_address", null: false
    t.datetime "updated_at", null: false
    t.text "user_agent", null: false
    t.string "user_yid", null: false
    t.index ["user_yid", "device_id"], name: "index_logins_on_user_yid_and_device_id", unique: true
  end

  create_table "members", primary_key: "yid", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "roles", default: [], null: false, array: true
    t.string "team_yid", null: false
    t.datetime "updated_at", null: false
    t.string "user_yid", null: false
    t.enum "visibility", default: "published", null: false, enum_type: "content_visibility"
    t.index ["team_yid", "user_yid"], name: "index_members_on_team_yid_and_user_yid", unique: true
    t.index ["user_yid"], name: "index_members_on_user_yid"
  end

  create_table "memories", primary_key: "yid", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "location_yid"
    t.text "memo", null: false
    t.string "picture_yid"
    t.string "team_yid", null: false
    t.datetime "updated_at", null: false
    t.enum "visibility", default: "draft", null: false, enum_type: "content_visibility"
    t.string "weblink_yid"
    t.index ["team_yid"], name: "index_memories_on_team_yid"
  end

  create_table "pg_search_documents", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "searchable_id", null: false
    t.string "searchable_type", null: false
    t.string "team_yid", null: false
    t.datetime "updated_at", null: false
    t.index ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable"
    t.index ["team_yid", "searchable_type"], name: "index_pg_search_documents_on_team_yid"
  end

  create_table "pictures", primary_key: "yid", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date"
    t.string "name"
    t.string "team_yid", null: false
    t.datetime "updated_at", null: false
    t.enum "visibility", default: "internal", null: false, enum_type: "content_visibility"
    t.index ["team_yid"], name: "index_pictures_on_team_yid"
  end

  create_table "record_histories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "done_by_admin", default: false, null: false
    t.string "event", null: false
    t.string "record_type", null: false
    t.string "record_yid", null: false
    t.string "team_yid", null: false
    t.datetime "updated_at", null: false
    t.string "user_yid", null: false
    t.index ["done_by_admin", "user_yid", "record_type"], name: "idx_on_done_by_admin_user_yid_record_type_f814bc5185"
    t.index ["event", "record_type", "team_yid"], name: "index_record_histories_on_event_and_record_type_and_team_yid"
    t.index ["event", "record_type", "user_yid"], name: "index_record_histories_on_event_and_record_type_and_user_yid"
    t.index ["team_yid", "record_type", "record_yid"], name: "index_record_histories_by_team_and_record"
  end

  create_table "teams", primary_key: "yid", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.jsonb "preferences", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_teams_on_name", unique: true
  end

  create_table "users", primary_key: "yid", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "nickname"
    t.string "password_digest", null: false
    t.jsonb "preferences", default: {}, null: false
    t.string "role", default: "user", null: false
    t.text "temp_auth_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["nickname"], name: "index_users_on_nickname", unique: true
    t.index ["temp_auth_token"], name: "index_users_on_temp_auth_token", unique: true
  end

  create_table "weblinks", primary_key: "yid", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date"
    t.text "description"
    t.string "name", null: false
    t.json "preview_snippet", default: {}
    t.string "team_yid", null: false
    t.datetime "updated_at", null: false
    t.text "url", null: false
    t.enum "visibility", default: "internal", null: false, enum_type: "content_visibility"
    t.index ["team_yid", "url"], name: "index_weblinks_on_team_yid_and_url", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "locations", "teams", column: "team_yid", primary_key: "yid"
  add_foreign_key "logins", "users", column: "user_yid", primary_key: "yid"
  add_foreign_key "members", "teams", column: "team_yid", primary_key: "yid"
  add_foreign_key "members", "users", column: "user_yid", primary_key: "yid"
  add_foreign_key "memories", "locations", column: "location_yid", primary_key: "yid"
  add_foreign_key "memories", "pictures", column: "picture_yid", primary_key: "yid"
  add_foreign_key "memories", "teams", column: "team_yid", primary_key: "yid"
  add_foreign_key "memories", "weblinks", column: "weblink_yid", primary_key: "yid"
  add_foreign_key "pg_search_documents", "teams", column: "team_yid", primary_key: "yid"
  add_foreign_key "pictures", "teams", column: "team_yid", primary_key: "yid"
  add_foreign_key "weblinks", "teams", column: "team_yid", primary_key: "yid"
end
