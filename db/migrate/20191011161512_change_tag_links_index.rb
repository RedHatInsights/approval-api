class ChangeTagLinksIndex < ActiveRecord::Migration[5.1]
  def change
    remove_index :tag_links, [:app_name, :object_type, :tag_name]
    add_index :tag_links, [:app_name, :object_type, :tag_name, :tenant_id], :unique => true, :name => 'index_tag_links_on_app_type_tag'
  end
end
