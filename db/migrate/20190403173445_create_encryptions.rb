class CreateEncryptions < ActiveRecord::Migration[5.1]
  def change
    create_table :encryptions do |t|
      t.bigint :tenant_id
      t.string :secret

      t.timestamps
    end
  end
end
