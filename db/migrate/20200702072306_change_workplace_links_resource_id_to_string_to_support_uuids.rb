class ChangeWorkplaceLinksResourceIdToStringToSupportUuids < ActiveRecord::Migration[6.0]
  def change
    change_column :worker_plugins_workplace_links, :resource_id, :string
  end
end
