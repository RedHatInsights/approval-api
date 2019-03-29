class AddRandomAccessKeyToStages < ActiveRecord::Migration[5.1]
  def change
    add_column :stages, :random_access_key, :string
    add_index  :stages, :random_access_key
  end
end
