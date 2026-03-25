class AddSessionIdToWorkerPluginsWorkplaces < ActiveRecord::Migration[6.0]
  def change
    add_column :worker_plugins_workplaces, :session_id, :string
    add_index :worker_plugins_workplaces, :session_id, unique: true
  end
end
