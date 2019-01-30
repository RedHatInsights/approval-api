class AddProcessSettingToTemplates < ActiveRecord::Migration[5.1]
  def change
    add_column    :templates, :process_setting, :jsonb
    add_column    :templates, :signal_setting,  :jsonb
    remove_column :templates, :ext_ref,         :string
  end
end
