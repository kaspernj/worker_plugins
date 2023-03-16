class ChangeWorkplaceLinksResourceIdToStringToSupportUuids < ActiveRecord::Migration[7.0]
  def up
    change_column :worker_plugins_workplace_links, :resource_id, :string
  end

  def down
    change_column :worker_plugins_workplace_links, :resource_id, :bigint
  end
end
