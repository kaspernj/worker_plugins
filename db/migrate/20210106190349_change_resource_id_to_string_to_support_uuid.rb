class ChangeResourceIdToStringToSupportUuid < ActiveRecord::Migration[6.1]
  def change
    change_column :worker_plugins_workplace_links, :resource_id, :string
  end
end
