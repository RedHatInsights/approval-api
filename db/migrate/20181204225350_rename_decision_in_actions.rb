class RenameDecisionInActions < ActiveRecord::Migration[5.1]
  def change
    rename_column :actions, :decision, :operation
  end
end
