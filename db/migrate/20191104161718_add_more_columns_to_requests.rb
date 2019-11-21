class AddMoreColumnsToRequests < ActiveRecord::Migration[5.1]
  def change
    add_column :requests, :random_access_key,           :string
    add_column :requests, :number_of_children,          :integer
    add_column :requests, :number_of_finished_children, :integer
    add_column :requests, :group_name,                  :string
    add_column :requests, :group_ref,                   :string
    add_column :requests, :notified_at,                 :datetime
    add_column :requests, :finished_at,                 :datetime

    add_index  :requests, :random_access_key
    add_index  :requests, :group_ref
  end
end
