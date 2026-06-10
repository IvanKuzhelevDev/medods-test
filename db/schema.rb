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

ActiveRecord::Schema[8.1].define(version: 2026_06_09_120004) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.boolean "system", default: false, null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "index_tags_on_lower_name", unique: true
  end

  create_table "task_occurrences", force: :cascade do |t|
    t.boolean "canceled", default: false, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.date "occurrence_date", null: false
    t.datetime "scheduled_at"
    t.string "status"
    t.bigint "task_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["task_id", "occurrence_date"], name: "index_task_occurrences_on_task_id_and_occurrence_date", unique: true
    t.index ["task_id"], name: "index_task_occurrences_on_task_id"
  end

  create_table "task_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "tag_id", null: false
    t.bigint "task_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_task_tags_on_tag_id"
    t.index ["task_id", "tag_id"], name: "index_task_tags_on_task_id_and_tag_id", unique: true
    t.index ["task_id"], name: "index_task_tags_on_task_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "days_of_month", default: [], array: true
    t.text "description"
    t.time "due_time"
    t.date "ends_on"
    t.string "parity"
    t.integer "recurrence_interval"
    t.string "recurrence_type", default: "once", null: false
    t.date "specific_dates", default: [], array: true
    t.date "starts_on"
    t.string "status", default: "new", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["starts_on"], name: "index_tasks_on_starts_on"
    t.index ["status"], name: "index_tasks_on_status"
  end

  add_foreign_key "task_occurrences", "tasks"
  add_foreign_key "task_tags", "tags"
  add_foreign_key "task_tags", "tasks"
end
