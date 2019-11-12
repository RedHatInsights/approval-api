class AddSequenceToWorkflows < ActiveRecord::Migration[5.2]
  def change
    add_column :workflows, :sequence, :integer
  end
end
