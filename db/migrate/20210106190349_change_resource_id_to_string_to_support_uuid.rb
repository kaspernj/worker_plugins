class ChangeResourceIdToStringToSupportUuid < ActiveRecord::Migration[6.1]
  def up
    change_column :worker_plugins_workplace_links, :resource_id, :string
  end

  def down
    change_column :worker_plugins_workplace_links, :resource_id, :bigint
  end
end
