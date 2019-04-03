class AddContextToRequest < ActiveRecord::Migration[5.2]
  def change
    add_column :requests, :context, :jsonb
  end
end
