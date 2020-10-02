class RemoveSequenceFromWorkflows < ActiveRecord::Migration[5.2]
  def change
    remove_index :workflows, column: [:sequence, :tenant_id], unique: true
    remove_column :workflows, :sequence, :integer
  end
end
