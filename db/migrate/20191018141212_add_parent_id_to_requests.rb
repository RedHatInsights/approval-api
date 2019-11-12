class AddParentIdToRequests < ActiveRecord::Migration[5.2]
  def change
    add_column :requests, :parent_id, :bigint

    add_index :requests, :parent_id
  end
end
