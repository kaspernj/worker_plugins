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

ActiveRecord::Schema.define(version: 2021_01_07_082836) do

  create_table "tasks", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_tasks_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "worker_plugins_workplace_links", force: :cascade do |t|
    t.integer "workplace_id", null: false
    t.string "resource_type", null: false
    t.string "resource_id", null: false
    t.json "custom_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["resource_type", "resource_id"], name: "index_on_resource"
    t.index ["workplace_id", "resource_type", "resource_id"], name: "unique_resource_on_workspace", unique: true
    t.index ["workplace_id"], name: "index_on_workplace_id"
  end

  create_table "worker_plugins_workplaces", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "active", default: false, null: false
    t.string "user_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_worker_plugins_workplaces_on_active"
    t.index ["user_type", "user_id"], name: "index_worker_plugins_workplaces_on_user"
  end

  add_foreign_key "tasks", "users"
  add_foreign_key "worker_plugins_workplace_links", "worker_plugins_workplaces", column: "workplace_id"
end
