class AddProcessRefToRequests < ActiveRecord::Migration[5.1]
  def change
    add_column :requests, :process_ref, :string
  end
end
