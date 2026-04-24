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

ActiveRecord::Schema[7.1].define(version: 2026_04_24_205544) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "brags", force: :cascade do |t|
    t.string "name"
    t.string "buid"
    t.text "message"
  end

  create_table "cords", id: false, force: :cascade do |t|
    t.string "buid", null: false
    t.string "cord_type", null: false
    t.index ["buid", "cord_type"], name: "index_cords_on_buid_and_cord_type", unique: true
  end

  create_table "graduates", primary_key: "buid", id: { type: :string, limit: 50 }, force: :cascade do |t|
    t.string "lastname", limit: 50
    t.string "suffix", limit: 50
    t.string "firstname", limit: 50
    t.string "middlename", limit: 50
    t.string "preferredlast", limit: 50
    t.string "preferredfirst", limit: 50
    t.string "honors", limit: 50
    t.string "levelcode", limit: 50
    t.string "college1", limit: 50
    t.string "collegedesc", limit: 50
    t.string "degree1", limit: 50
    t.string "hoodcolor", limit: 50
    t.string "campusemail", limit: 50
    t.string "fullname", limit: 50
    t.string "buid2", limit: 50
    t.string "orderid", limit: 50
    t.integer "height"
    t.datetime "checked_in", precision: nil
    t.datetime "printed", precision: nil
    t.string "major"
    t.string "degstatus", limit: 50
    t.string "degstatusdesc", limit: 50
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
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

end
