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

  create_table "actions", id: :serial, force: :cascade do |t|
    t.string "processed_by"
    t.datetime "actioned_at"
    t.datetime "notified_at"
    t.string "decision"
    t.string "comments"
    t.bigint "stage_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stage_id"], name: "index_actions_on_stage_id"
  end

  create_table "groups", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "contact_method"
    t.jsonb "contact_setting"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "requests", id: :serial, force: :cascade do |t|
    t.string "requester"
    t.string "name"
    t.string "description"
    t.string "state"
    t.string "decision"
    t.string "reason"
    t.jsonb "content"
    t.bigint "workflow_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workflow_id"], name: "index_requests_on_workflow_id"
  end

  create_table "stages", id: :serial, force: :cascade do |t|
    t.string "state"
    t.string "decision"
    t.string "comments"
    t.bigint "group_id"
    t.bigint "request_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_stages_on_group_id"
    t.index ["request_id"], name: "index_stages_on_request_id"
  end

  create_table "templates", id: :serial, force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "workflowgroups", id: :serial, force: :cascade do |t|
    t.bigint "workflow_id"
    t.bigint "group_id"
    t.index ["group_id"], name: "index_workflowgroups_on_group_id"
    t.index ["workflow_id"], name: "index_workflowgroups_on_workflow_id"
  end

  create_table "workflows", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.bigint "template_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["template_id"], name: "index_workflows_on_template_id"
  end

  add_foreign_key "requests", "workflows"
  add_foreign_key "stages", "groups"
  add_foreign_key "stages", "requests"
  add_foreign_key "workflowgroups", "groups"
  add_foreign_key "workflowgroups", "workflows"
  add_foreign_key "workflows", "templates"
end
