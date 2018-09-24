class CreateWorkflows < ActiveRecord::Migration[5.1]
  def change
    create_table :workflows do |t|
      t.string :name
      t.string :groups
      t.references :template, foreign_key: true
    end
  end
end
