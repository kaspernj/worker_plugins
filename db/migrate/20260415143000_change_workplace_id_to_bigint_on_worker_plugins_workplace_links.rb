class ChangeWorkplaceIdToBigintOnWorkerPluginsWorkplaceLinks < ActiveRecord::Migration[6.0]
  def up
    change_column :worker_plugins_workplace_links, :workplace_id, :bigint, null: false
  end

  def down
    change_column :worker_plugins_workplace_links, :workplace_id, :integer, null: false
  end
end
