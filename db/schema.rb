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

ActiveRecord::Schema[8.0].define(version: 2024_11_04_193138) do
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

  create_table "ahoy_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.jsonb "properties"
    t.datetime "time"
    t.string "user_id"
    t.uuid "visit_id"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["properties"], name: "index_ahoy_events_on_properties", opclass: :jsonb_path_ops, using: :gin
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "app_version"
    t.string "browser"
    t.string "city"
    t.string "country"
    t.string "device_type"
    t.string "ip"
    t.text "landing_page"
    t.float "latitude"
    t.float "longitude"
    t.string "os"
    t.string "os_version"
    t.string "platform"
    t.text "referrer"
    t.string "referring_domain"
    t.string "region"
    t.datetime "started_at"
    t.text "user_agent"
    t.string "user_id"
    t.string "utm_campaign"
    t.string "utm_content"
    t.string "utm_medium"
    t.string "utm_source"
    t.string "utm_term"
    t.string "visit_token"
    t.string "visitor_token"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
    t.index ["visitor_token", "started_at"], name: "index_ahoy_visits_on_visitor_token_and_started_at"
  end

  create_table "locations", id: :string, force: :cascade do |t|
    t.string "address"
    t.string "country_code", null: false
    t.datetime "created_at", null: false
    t.date "date"
    t.string "description"
    t.jsonb "geocoded_address", default: {}, null: false
    t.decimal "lat"
    t.decimal "long"
    t.string "name", null: false
    t.string "team_id", null: false
    t.datetime "updated_at", null: false
    t.text "url"
    t.enum "visibility", default: "internal", null: false, enum_type: "content_visibility"
    t.index ["country_code"], name: "index_locations_on_country_code"
    t.index ["team_id", "name"], name: "index_locations_on_team_id_and_name", unique: true
  end

  create_table "logins", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "device_id", null: false
    t.string "ip_address", null: false
    t.datetime "updated_at", null: false
    t.text "user_agent", null: false
    t.string "user_id", null: false
    t.index ["user_id", "device_id"], name: "index_logins_on_user_id_and_device_id", unique: true
  end

  create_table "members", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "roles", default: [], null: false, array: true
    t.string "team_id", null: false
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.enum "visibility", default: "published", null: false, enum_type: "content_visibility"
    t.index ["team_id", "user_id"], name: "index_members_on_team_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_members_on_user_id"
  end

  create_table "memories", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "location_id"
    t.text "memo", null: false
    t.string "picture_id"
    t.string "team_id", null: false
    t.string "thought_id"
    t.datetime "updated_at", null: false
    t.enum "visibility", default: "draft", null: false, enum_type: "content_visibility"
    t.string "weblink_id"
    t.index ["team_id"], name: "index_memories_on_team_id"
  end

  create_table "pg_search_documents", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "searchable_id", null: false
    t.string "searchable_type", null: false
    t.string "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable"
    t.index ["team_id", "searchable_type"], name: "index_pg_search_documents_on_team_id"
  end

  create_table "pictures", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date"
    t.string "name"
    t.string "team_id", null: false
    t.datetime "updated_at", null: false
    t.enum "visibility", default: "internal", null: false, enum_type: "content_visibility"
    t.index ["team_id"], name: "index_pictures_on_team_id"
  end

  create_table "record_histories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "done_by_admin", default: false, null: false
    t.string "event", null: false
    t.string "record_id", null: false
    t.string "record_type", null: false
    t.string "team_id", null: false
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index ["done_by_admin", "user_id", "record_type"], name: "idx_on_done_by_admin_user_id_record_type_a6550ac183"
    t.index ["event", "record_type", "team_id"], name: "index_record_histories_on_event_and_record_type_and_team_id"
    t.index ["event", "record_type", "user_id"], name: "index_record_histories_on_event_and_record_type_and_user_id"
    t.index ["team_id", "record_type", "record_id"], name: "index_record_histories_by_team_and_record"
  end

  create_table "teams", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.jsonb "preferences", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_teams_on_name", unique: true
  end

  create_table "thoughts", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date"
    t.virtual "name", type: :string, as: "(\"substring\"(text, 0, 60) || '...'::text)", stored: true
    t.string "team_id", null: false
    t.text "text", null: false
    t.datetime "updated_at", null: false
    t.enum "visibility", default: "internal", null: false, enum_type: "content_visibility"
    t.index ["team_id", "date"], name: "index_thoughts_on_team_id_and_date"
  end

  create_table "users", id: :string, force: :cascade do |t|
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

  create_table "weblinks", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date"
    t.text "description"
    t.string "name", null: false
    t.json "preview_snippet", default: {}
    t.string "team_id", null: false
    t.datetime "updated_at", null: false
    t.text "url", null: false
    t.enum "visibility", default: "internal", null: false, enum_type: "content_visibility"
    t.index ["team_id", "url"], name: "index_weblinks_on_team_id_and_url", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ahoy_events", "ahoy_visits", column: "visit_id"
  add_foreign_key "locations", "teams"
  add_foreign_key "logins", "users"
  add_foreign_key "members", "teams"
  add_foreign_key "members", "users"
  add_foreign_key "memories", "locations"
  add_foreign_key "memories", "pictures"
  add_foreign_key "memories", "teams"
  add_foreign_key "memories", "thoughts"
  add_foreign_key "memories", "weblinks"
  add_foreign_key "pg_search_documents", "teams"
  add_foreign_key "pictures", "teams"
  add_foreign_key "thoughts", "teams"
  add_foreign_key "weblinks", "teams"
end
