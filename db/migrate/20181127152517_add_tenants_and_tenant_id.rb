class AddTenantsAndTenantId < ActiveRecord::Migration[5.1]
  def change
    create_table :tenants do |t|
      t.bigint :external_tenant
      t.index ["external_tenant"], :name => "index_tenants_on_external_tenant"
      t.string :name
      t.string :description

      t.timestamps
    end

    add_column :actions, :tenant_id, :bigint
    add_index  :actions, :tenant_id

    add_column :groups, :tenant_id, :bigint
    add_index  :groups, :tenant_id

    add_column :requests, :tenant_id, :bigint
    add_index  :requests, :tenant_id

    add_column :stages, :tenant_id, :bigint
    add_index  :stages, :tenant_id

    add_column :templates, :tenant_id, :bigint
    add_index  :templates, :tenant_id

    add_column :workflows, :tenant_id, :bigint
    add_index  :workflows, :tenant_id
  end
end
