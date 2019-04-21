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

ActiveRecord::Schema.define(version: 2019_04_21_110143) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "user"
    t.string "rakuten_app_id"
    t.string "yahoo_app_id"
    t.string "progress"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "selected_shop_id"
    t.datetime "search_start"
    t.text "last_keyword"
    t.string "last_category_id"
    t.string "last_store_id"
    t.string "selected_group"
  end

  create_table "categories", force: :cascade do |t|
    t.string "category_id"
    t.string "name"
    t.string "shop_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id", "shop_id"], name: "for_upsert_categories", unique: true
  end

  create_table "feed_products", force: :cascade do |t|
    t.string "group"
    t.string "name"
    t.string "feed_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "list_templates", force: :cascade do |t|
    t.string "user"
    t.string "shop_id"
    t.string "list_type"
    t.string "header"
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "lists", force: :cascade do |t|
    t.string "user"
    t.string "shop_id"
    t.string "product_id"
    t.string "status"
    t.integer "price"
    t.string "condition"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user", "product_id", "shop_id"], name: "for_upsert_lists", unique: true
  end

  create_table "prices", force: :cascade do |t|
    t.string "user"
    t.integer "original_price"
    t.integer "convert_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "products", force: :cascade do |t|
    t.string "product_id"
    t.string "shop_id"
    t.text "title"
    t.integer "price"
    t.string "image1"
    t.string "image2"
    t.string "image3"
    t.string "brand"
    t.string "part_number"
    t.text "description"
    t.string "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "jan"
    t.index ["product_id", "shop_id"], name: "for_upsert_products", unique: true
  end

  create_table "shops", force: :cascade do |t|
    t.string "shop_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin_flg"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
