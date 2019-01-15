class CreateApprovers < ActiveRecord::Migration[5.1]
  def change
    create_table :approvers do |t|
      t.bigint :tenant_id
      t.string :email
      t.string :first_name
      t.string :last_name

      t.timestamps
    end

    create_table :approvergroups do |t|
      t.references :approver, :foreign_key => true
      t.references :group, :foreign_key => true
    end

    remove_column :groups, :contact_setting, :string
    remove_column :groups, :contact_method, :string
  end
end
