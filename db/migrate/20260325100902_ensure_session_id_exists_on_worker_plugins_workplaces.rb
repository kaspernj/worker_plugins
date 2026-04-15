class EnsureSessionIdExistsOnWorkerPluginsWorkplaces < ActiveRecord::Migration[6.0]
  def change
    add_column :worker_plugins_workplaces, :session_id, :string unless column_exists?(:worker_plugins_workplaces, :session_id)
    add_index :worker_plugins_workplaces, :session_id, unique: true unless index_exists?(:worker_plugins_workplaces, :session_id)
  end
end
