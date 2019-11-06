class CreateWorkerPluginsWorkplaceLinks < ActiveRecord::Migration[5.2]
  def change
    create_table :worker_plugins_workplace_links do |t|
      t.references :workplace, index: {name: "index_on_workplace_id"}, foreign_key: {to_table: :worker_plugins_workplaces}, null: false
      t.belongs_to :resource, index: {name: "index_on_resource"}, null: false, polymorphic: true

      if postgres?
        t.jsonb :custom_data
      else
        t.json :custom_data
      end

      t.timestamps
    end

    add_index :worker_plugins_workplace_links, [:workplace_id, :resource_type, :resource_id], unique: true, name: "unique_resource_on_workspace"
  end

  def postgres?
    connection.adapter_name.downcase.include?("postgres")
  end
end
