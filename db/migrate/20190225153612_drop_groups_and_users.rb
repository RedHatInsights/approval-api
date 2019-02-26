class DropGroupsAndUsers < ActiveRecord::Migration[5.1]
  def up
    remove_column :stages, :group_id
    add_column    :stages, :group_ref, :string
    add_index     :stages, :group_ref

    add_column    :workflows, :group_refs, :jsonb, :array => true, :default => []

    drop_table    :workflowgroups
    drop_table    :usergroups
    drop_table    :groups
    drop_table    :users
  end

  def down
    create_table :users do |t|
      t.bigint :tenant_id
      t.string :email
      t.string :first_name
      t.string :last_name

      t.timestamps
    end

    create_table :groups do |t|
      t.string "name"
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
      t.bigint "tenant_id"
    end

    create_table :usergroups do |t|
      t.references :user,  :foreign_key => true
      t.references :group, :foreign_key => true
    end

    create_table :workflowgroups do |t|
      t.bigint "workflow_id", :foreign_key => true
      t.bigint "group_id",    :foreign_key => true
    end

    remove_column :stages, :group_ref
    add_column    :stages, :group_id, :bigint

    remove_column :workflows, :group_refs
  end
end
