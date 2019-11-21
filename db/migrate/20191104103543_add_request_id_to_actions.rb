class AddRequestIdToActions < ActiveRecord::Migration[5.2]
  def change
    remove_column :actions, :stage_id,   :bigint
    add_column    :actions, :request_id, :bigint
    add_index     :actions, :request_id
  end
end
