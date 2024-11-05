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

ActiveRecord::Schema[8.0].define(version: 2024_11_05_202731) do
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
    t.string "user_yid", null: false
    t.string "utm_campaign"
    t.string "utm_content"
    t.string "utm_medium"
    t.string "utm_source"
    t.string "utm_term"
    t.string "visit_token"
    t.string "visitor_token"
    t.index ["user_yid"], name: "index_ahoy_visits_on_user_yid"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
    t.index ["visitor_token", "started_at"], name: "index_ahoy_visits_on_visitor_token_and_started_at"
  end

  create_table "blazer_audits", force: :cascade do |t|
    t.datetime "created_at"
    t.string "data_source"
    t.bigint "query_id"
    t.text "statement"
    t.bigint "user_id"
    t.index ["query_id"], name: "index_blazer_audits_on_query_id"
    t.index ["user_id"], name: "index_blazer_audits_on_user_id"
  end

  create_table "blazer_checks", force: :cascade do |t|
    t.string "check_type"
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.text "emails"
    t.datetime "last_run_at"
    t.text "message"
    t.bigint "query_id"
    t.string "schedule"
    t.text "slack_channels"
    t.string "state"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_checks_on_creator_id"
    t.index ["query_id"], name: "index_blazer_checks_on_query_id"
  end

  create_table "blazer_dashboard_queries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "dashboard_id"
    t.integer "position"
    t.bigint "query_id"
    t.datetime "updated_at", null: false
    t.index ["dashboard_id"], name: "index_blazer_dashboard_queries_on_dashboard_id"
    t.index ["query_id"], name: "index_blazer_dashboard_queries_on_query_id"
  end

  create_table "blazer_dashboards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_dashboards_on_creator_id"
  end

  create_table "blazer_queries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.string "data_source"
    t.text "description"
    t.string "name"
    t.text "statement"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_queries_on_creator_id"
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
    t.string "thought_yid"
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

  create_table "record_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "done_by_admin", default: false, null: false
    t.string "name", null: false
    t.jsonb "properties"
    t.string "record_type", null: false
    t.string "record_yid", null: false
    t.string "team_yid"
    t.virtual "time", type: :text, as: "created_at", stored: true
    t.datetime "updated_at", null: false
    t.string "user_yid"
    t.uuid "visit_id"
    t.index ["done_by_admin", "user_yid", "record_type"], name: "idx_on_done_by_admin_user_yid_record_type_b2508dc761"
    t.index ["name", "record_type", "team_yid"], name: "index_record_events_on_name_and_record_type_and_team_yid"
    t.index ["name", "record_type", "user_yid"], name: "index_record_events_on_name_and_record_type_and_user_yid"
    t.index ["name", "time"], name: "index_record_events_on_name_and_time"
    t.index ["properties"], name: "index_record_events_on_properties", opclass: :jsonb_path_ops, using: :gin
    t.index ["team_yid", "record_type", "record_yid"], name: "index_record_histories_by_team_and_record"
    t.index ["visit_id"], name: "index_record_events_on_visit_id"
  end

  create_table "teams", primary_key: "yid", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.jsonb "preferences", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_teams_on_name", unique: true
  end

  create_table "thoughts", primary_key: "yid", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date"
    t.virtual "name", type: :string, as: "(\"substring\"(text, 0, 60) || '...'::text)", stored: true
    t.string "team_yid", null: false
    t.text "text", null: false
    t.datetime "updated_at", null: false
    t.enum "visibility", default: "internal", null: false, enum_type: "content_visibility"
    t.index ["team_yid", "date"], name: "index_thoughts_on_team_yid_and_date"
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
  add_foreign_key "ahoy_visits", "users", column: "user_yid", primary_key: "yid"
  add_foreign_key "locations", "teams", column: "team_yid", primary_key: "yid"
  add_foreign_key "logins", "users", column: "user_yid", primary_key: "yid"
  add_foreign_key "members", "teams", column: "team_yid", primary_key: "yid"
  add_foreign_key "members", "users", column: "user_yid", primary_key: "yid"
  add_foreign_key "memories", "locations", column: "location_yid", primary_key: "yid"
  add_foreign_key "memories", "pictures", column: "picture_yid", primary_key: "yid"
  add_foreign_key "memories", "teams", column: "team_yid", primary_key: "yid"
  add_foreign_key "memories", "thoughts", column: "thought_yid", primary_key: "yid"
  add_foreign_key "memories", "weblinks", column: "weblink_yid", primary_key: "yid"
  add_foreign_key "pg_search_documents", "teams", column: "team_yid", primary_key: "yid"
  add_foreign_key "pictures", "teams", column: "team_yid", primary_key: "yid"
  add_foreign_key "thoughts", "teams", column: "team_yid", primary_key: "yid"
  add_foreign_key "weblinks", "teams", column: "team_yid", primary_key: "yid"
end
