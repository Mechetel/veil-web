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

ActiveRecord::Schema[8.1].define(version: 2026_06_09_120001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
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

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "analyses", force: :cascade do |t|
    t.string "core_job_id"
    t.datetime "created_at", null: false
    t.datetime "enqueued_at"
    t.text "error_message"
    t.datetime "finished_at"
    t.bigint "input_image_id", null: false
    t.jsonb "params", default: {}, null: false
    t.jsonb "result", default: {}, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["core_job_id"], name: "index_analyses_on_core_job_id"
    t.index ["created_at"], name: "index_analyses_on_created_at"
    t.index ["input_image_id"], name: "index_analyses_on_input_image_id"
    t.index ["user_id"], name: "index_analyses_on_user_id"
  end

  create_table "decodings", force: :cascade do |t|
    t.string "core_job_id"
    t.datetime "created_at", null: false
    t.datetime "enqueued_at"
    t.text "error_message"
    t.datetime "finished_at"
    t.bigint "input_image_id", null: false
    t.jsonb "params", default: {}, null: false
    t.jsonb "result", default: {}, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["core_job_id"], name: "index_decodings_on_core_job_id"
    t.index ["created_at"], name: "index_decodings_on_created_at"
    t.index ["input_image_id"], name: "index_decodings_on_input_image_id"
    t.index ["user_id"], name: "index_decodings_on_user_id"
  end

  create_table "embeddings", force: :cascade do |t|
    t.string "core_job_id"
    t.datetime "created_at", null: false
    t.datetime "enqueued_at"
    t.text "error_message"
    t.datetime "finished_at"
    t.bigint "input_image_id", null: false
    t.bigint "output_image_id"
    t.jsonb "params", default: {}, null: false
    t.jsonb "result", default: {}, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["core_job_id"], name: "index_embeddings_on_core_job_id"
    t.index ["created_at"], name: "index_embeddings_on_created_at"
    t.index ["input_image_id"], name: "index_embeddings_on_input_image_id"
    t.index ["output_image_id"], name: "index_embeddings_on_output_image_id"
    t.index ["user_id"], name: "index_embeddings_on_user_id"
  end

  create_table "images", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "kind", default: 0, null: false
    t.jsonb "metadata", default: {}, null: false
    t.integer "origin", default: 0, null: false
    t.bigint "source_embedding_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["created_at"], name: "index_images_on_created_at"
    t.index ["source_embedding_id"], name: "index_images_on_source_embedding_id"
    t.index ["user_id"], name: "index_images_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true, where: "(username IS NOT NULL)"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "analyses", "images", column: "input_image_id", on_delete: :cascade
  add_foreign_key "analyses", "users"
  add_foreign_key "decodings", "images", column: "input_image_id", on_delete: :cascade
  add_foreign_key "decodings", "users"
  add_foreign_key "embeddings", "images", column: "input_image_id", on_delete: :cascade
  add_foreign_key "embeddings", "images", column: "output_image_id", on_delete: :nullify
  add_foreign_key "embeddings", "users"
  add_foreign_key "images", "users"
  add_foreign_key "sessions", "users"
end
