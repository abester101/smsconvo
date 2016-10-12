# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20161004134442) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "api_keys", force: :cascade do |t|
    t.string   "access_token"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "messages", force: :cascade do |t|
    t.text     "body"
    t.boolean  "from_us"
    t.integer  "user_id"
    t.boolean  "delivered"
    t.text     "media_url"
    t.string   "media_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "senders", force: :cascade do |t|
    t.string   "phone"
    t.string   "sid"
    t.string   "friendly_name"
    t.string   "country_code"
    t.string   "region"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "phone"
    t.boolean  "subscribed"
    t.string   "state"
    t.string   "country"
    t.integer  "zip"
    t.string   "city"
    t.boolean  "needs_response"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.integer  "sender_id"
    t.string   "created_from"
    t.boolean  "sent_welcome",   default: false
    t.string   "caller_name"
    t.string   "country_code"
    t.string   "carrier_name"
    t.string   "patron_product"
    t.index ["sender_id"], name: "index_users_on_sender_id", using: :btree
  end

  add_foreign_key "users", "senders"
end
