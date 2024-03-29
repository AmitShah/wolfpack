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

ActiveRecord::Schema.define(version: 20160203015617) do

  create_table "agent_to_wolves", force: :cascade do |t|
    t.integer  "wolf_id"
    t.integer  "agent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "agents", force: :cascade do |t|
    t.string   "username"
    t.text     "cookie"
    t.string   "agent_type"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.boolean  "available",  default: true
  end

  create_table "tasks", force: :cascade do |t|
    t.string   "medium"
    t.string   "target"
    t.string   "action"
    t.integer  "wolf_count"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "tickets", force: :cascade do |t|
    t.integer  "task_id"
    t.integer  "agent_id"
    t.integer  "wolf_id"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "wolves", force: :cascade do |t|
    t.string   "instance_id"
    t.string   "ip_address"
    t.string   "key"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

end
