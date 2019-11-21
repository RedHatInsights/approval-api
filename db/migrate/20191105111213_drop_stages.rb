class DropStages < ActiveRecord::Migration[5.1]
  def change
    drop_table :stages do |t|
      t.string "state"
      t.string "decision"
      t.string "reason"
      t.bigint "request_id"
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
      t.bigint "tenant_id"
      t.string "group_ref"
      t.string "random_access_key"
      t.index ["group_ref"],         :name => "index_stages_on_group_ref"
      t.index ["random_access_key"], :name => "index_stages_on_random_access_key"
      t.index ["request_id"],        :name => "index_stages_on_request_id"
      t.index ["tenant_id"],         :name => "index_stages_on_tenant_id"
    end
  end
end
