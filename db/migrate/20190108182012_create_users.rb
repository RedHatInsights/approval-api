class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.bigint :tenant_id
      t.string :email
      t.string :first_name
      t.string :last_name

      t.timestamps
    end

    create_table :usergroups do |t|
      t.references :user, :foreign_key => true
      t.references :group, :foreign_key => true
    end

    remove_column :groups, :contact_setting, :string
    remove_column :groups, :contact_method, :string
  end
end
