class AddUniqueIndexToSequence < ActiveRecord::Migration[5.2]
  def change
    add_index :workflows, [:sequence, :tenant_id], unique: true
  end
end
