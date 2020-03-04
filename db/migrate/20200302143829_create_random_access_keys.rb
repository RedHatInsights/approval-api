class CreateRandomAccessKeys < ActiveRecord::Migration[5.2]
  def change
    create_table :random_access_keys do |t|
      t.bigint :tenant_id
      t.bigint :request_id
      t.string :approver_name
      t.string :access_key
      t.timestamps

      t.index :access_key
      t.index :tenant_id
    end

    remove_column :requests, :random_access_key, :string
  end
end
