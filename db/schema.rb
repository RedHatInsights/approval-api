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

ActiveRecord::Schema.define(version: 2019_04_02_165411) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "actions", force: :cascade do |t|
    t.string "processed_by"
    t.string "operation"
    t.string "comments"
    t.bigint "stage_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id"
    t.index ["stage_id"], name: "index_actions_on_stage_id"
    t.index ["tenant_id"], name: "index_actions_on_tenant_id"
  end

  create_table "requests", force: :cascade do |t|
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
    t.bigint "tenant_id"
    t.string "process_ref"
    t.jsonb "context"
    t.index ["tenant_id"], name: "index_requests_on_tenant_id"
    t.index ["workflow_id"], name: "index_requests_on_workflow_id"
  end

  create_table "stages", force: :cascade do |t|
    t.string "state"
    t.string "decision"
    t.string "reason"
    t.bigint "request_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id"
    t.string "group_ref"
    t.string "random_access_key"
    t.index ["group_ref"], name: "index_stages_on_group_ref"
    t.index ["request_id"], name: "index_stages_on_request_id"
    t.index ["random_access_key"], name: "index_stages_on_random_access_key"
    t.index ["tenant_id"], name: "index_stages_on_tenant_id"
  end

  create_table "templates", force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id"
    t.jsonb "process_setting"
    t.jsonb "signal_setting"
    t.index ["tenant_id"], name: "index_templates_on_tenant_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.bigint "external_tenant"
    t.string "name"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_tenant"], name: "index_tenants_on_external_tenant"
  end

  create_table "workflows", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.bigint "template_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id"
    t.jsonb "group_refs", default: [], array: true
    t.index ["template_id"], name: "index_workflows_on_template_id"
    t.index ["tenant_id"], name: "index_workflows_on_tenant_id"
  end

  add_foreign_key "requests", "workflows"
  add_foreign_key "stages", "requests"
  add_foreign_key "workflows", "templates"
end
