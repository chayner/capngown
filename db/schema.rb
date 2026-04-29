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

ActiveRecord::Schema[7.1].define(version: 2026_04_29_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "fuzzystrmatch"
  enable_extension "pg_trgm"
  enable_extension "plpgsql"
  enable_extension "unaccent"

  create_table "brags", force: :cascade do |t|
    t.string "name"
    t.string "buid"
    t.text "message"
    t.string "transaction_id"
    t.index ["buid"], name: "index_brags_on_buid"
    t.index ["transaction_id"], name: "index_brags_on_transaction_id", unique: true
  end

  create_table "cords", id: false, force: :cascade do |t|
    t.string "buid", null: false
    t.string "cord_type", null: false
    t.index ["buid", "cord_type"], name: "index_cords_on_buid_and_cord_type", unique: true
  end

  create_table "graduates", primary_key: "buid", id: { type: :string, limit: 50 }, force: :cascade do |t|
    t.string "lastname"
    t.string "suffix"
    t.string "firstname"
    t.string "middlename"
    t.string "preferredlast"
    t.string "preferredfirst"
    t.string "honors"
    t.string "levelcode"
    t.string "college1"
    t.string "collegedesc"
    t.string "degree1"
    t.string "hoodcolor"
    t.string "campusemail"
    t.string "fullname"
    t.string "buid2"
    t.string "orderid"
    t.integer "height"
    t.datetime "checked_in", precision: nil
    t.datetime "printed", precision: nil
    t.string "major"
    t.string "degstatus"
    t.string "degstatusdesc"
    t.string "graduation_term"
    t.text "notes"
    t.index ["graduation_term"], name: "index_graduates_on_graduation_term"
  end

  create_table "import_logs", force: :cascade do |t|
    t.bigint "user_id"
    t.string "import_type", null: false
    t.string "filename"
    t.integer "row_count", default: 0, null: false
    t.integer "inserts", default: 0, null: false
    t.integer "updates", default: 0, null: false
    t.integer "skipped", default: 0, null: false
    t.string "graduation_term"
    t.boolean "succeeded", default: false, null: false
    t.text "error_message"
    t.text "warnings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_import_logs_on_created_at"
    t.index ["import_type"], name: "index_import_logs_on_import_type"
    t.index ["user_id"], name: "index_import_logs_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true, null: false
    t.boolean "must_change_password", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "import_logs", "users"
end
