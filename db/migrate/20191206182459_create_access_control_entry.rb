class CreateAccessControlEntry < ActiveRecord::Migration[5.2]
  def change
    create_table :access_control_entries do |t|
      t.string :group_uuid
      t.bigint :tenant_id
      t.string :permission
      t.references :aceable, :name => :access_control_entries, :polymorphic => true
      t.timestamps

      t.index [:group_uuid, :permission, :aceable_type], :name => "index_ace_on_group_uuid_aceable_type_permission"
      t.index :tenant_id
    end
  end
end
