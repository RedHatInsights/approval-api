class ChangeActionAndStageColumnNames < ActiveRecord::Migration[5.1]
  def change
    rename_column :actions, :decision, :operation
    rename_column :stages,  :comments, :reason
    remove_column :actions, :notified_at, :datetime
    remove_column :actions, :actioned_at, :datetime
  end
end
