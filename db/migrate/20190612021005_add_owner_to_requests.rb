class AddOwnerToRequests < ActiveRecord::Migration[5.2]
  def change
    rename_column :requests, :requester, :requester_name
    add_column :requests, :owner, :string
  end
end
