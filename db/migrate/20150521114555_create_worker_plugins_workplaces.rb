class CreateWorkerPluginsWorkplaces < ActiveRecord::Migration
  def change
    create_table :worker_plugins_workplaces do |t|
      t.string :name
      t.boolean :active
      t.belongs_to :user, polymorphic: true
      t.timestamps
    end

    add_index :worker_plugins_workplaces, :user_id
    add_index :worker_plugins_workplaces, :active
  end
end
