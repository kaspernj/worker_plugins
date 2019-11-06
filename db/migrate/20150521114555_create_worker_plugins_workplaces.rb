class CreateWorkerPluginsWorkplaces < ActiveRecord::Migration[5.2]
  def change
    create_table :worker_plugins_workplaces do |t|
      t.string :name, null: false
      t.boolean :active, default: false, index: true, null: false
      t.belongs_to :user, index: true, polymorphic: true
      t.timestamps
    end
  end
end
