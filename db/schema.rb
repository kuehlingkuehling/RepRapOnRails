# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20140906190304) do

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "filaments", force: true do |t|
    t.text     "name"
    t.integer  "extrusion_temp"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "log_entries", force: true do |t|
    t.integer  "level"
    t.text     "line"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "preheating_profile", force: true do |t|
    t.string   "name"
    t.integer  "chamber_temp"
    t.integer  "bed_temp"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "preheating_profiles", force: true do |t|
    t.string   "name"
    t.integer  "chamber_temp"
    t.integer  "bed_temp"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "printjobs", force: true do |t|
    t.string   "name"
    t.string   "gcodefile"
    t.string   "note"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.float    "estimated_print_time"
  end

  create_table "settings", force: true do |t|
    t.string   "var",                   null: false
    t.text     "value"
    t.integer  "thing_id"
    t.string   "thing_type", limit: 30
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  add_index "settings", ["thing_type", "thing_id", "var"], name: "index_settings_on_thing_type_and_thing_id_and_var", unique: true, using: :btree

end
