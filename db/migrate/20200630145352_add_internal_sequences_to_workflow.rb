class AddInternalSequencesToWorkflow < ActiveRecord::Migration[5.2]
  def change
    add_column :workflows, :internal_sequence, :decimal

    add_index  :workflows, [:internal_sequence, :tenant_id], :unique => true

    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE workflows SET internal_sequence = sequence;
        SQL
      end
    end
  end
end
