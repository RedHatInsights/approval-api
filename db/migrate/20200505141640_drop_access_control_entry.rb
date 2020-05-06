class DropAccessControlEntry < ActiveRecord::Migration[5.2]
  def change
    drop_table :access_control_entries do |t|
      t.string "group_uuid"
      t.bigint "tenant_id"
      t.string "permission"
      t.string "aceable_type"
      t.bigint "aceable_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["aceable_type", "aceable_id"], name: "index_access_control_entries_on_aceable_type_and_aceable_id"
      t.index ["group_uuid", "permission", "aceable_type"], name: "index_ace_on_group_uuid_aceable_type_permission"
      t.index ["tenant_id"], name: "index_access_control_entries_on_tenant_id"
    end
  end
end
