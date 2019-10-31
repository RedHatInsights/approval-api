class CreateRequestContexts < ActiveRecord::Migration[5.1]
  def change
    create_table :request_contexts do |t|
      t.jsonb :content
      t.jsonb :context
    end

    add_column :requests, :request_context_id, :bigint
    remove_column :requests, :content, :jsonb
    remove_column :requests, :context, :jsonb
  end
end
