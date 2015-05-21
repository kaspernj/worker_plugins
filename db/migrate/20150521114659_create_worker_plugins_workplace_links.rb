class CreateWorkerPluginsWorkplaceLinks < ActiveRecord::Migration
  def change
    create_table :worker_plugins_workplace_links do |t|
      t.belongs_to :workplace
      t.belongs_to :resource, polymorphic: true
      t.text :custom_data
      t.timestamps
    end

    add_index :worker_plugins_workplace_links, :workplace_id
    add_index :worker_plugins_workplace_links, [:workplace_id, :resource_type, :resource_id], unique: true, name: 'unique_resource_on_workspace'
  end
end
