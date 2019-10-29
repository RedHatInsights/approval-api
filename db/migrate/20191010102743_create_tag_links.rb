class CreateTagLinks < ActiveRecord::Migration[5.1]
  def change
    create_table :tag_links do |t|
      t.bigint :tenant_id
      t.bigint :workflow_id
      t.string :app_name
      t.string :object_type
      t.string :tag_name

      t.timestamps
    end

    add_index :tag_links, [:app_name, :object_type, :tag_name], :unique => true
  end
end
