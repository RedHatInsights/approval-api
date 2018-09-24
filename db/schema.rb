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

ActiveRecord::Schema.define(version: 0) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "groups", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "action"
    t.string "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "requests", id: :serial, force: :cascade do |t|
    t.string "uuid"
    t.string "name"
    t.string "requested_by"
    t.string "state"
    t.string "status"
    t.string "content"
    t.bigint "workflow_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workflow_id"], name: "index_requests_on_workflow_id"
  end

  create_table "templates", id: :serial, force: :cascade do |t|
    t.string "description"
    t.string "title"
    t.string "created_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "workflows", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "groups"
    t.bigint "template_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["template_id"], name: "index_workflows_on_template_id"
  end

  add_foreign_key "requests", "workflows"
  add_foreign_key "workflows", "templates"
end
