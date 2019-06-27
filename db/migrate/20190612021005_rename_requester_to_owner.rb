class RenameRequesterToOwner < ActiveRecord::Migration[5.2]
  def change
    rename_column :requests, :requester, :owner
  end
end
