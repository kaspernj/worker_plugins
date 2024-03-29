require "rails_helper"

describe WorkerPlugins::AddQuery do
  let(:task1) { create :task }
  let(:task2) { create :task }
  let(:link1) { create :workplace_link, resource: task1, workplace: }
  let(:result) { WorkerPlugins::AddQuery.execute!(query: Task.all, workplace:) }
  let(:service) { WorkerPlugins::AddQuery.new(query: Task.all, workplace:) }
  let(:user) { create :user }
  let(:workplace) { create :workplace, user: }

  describe "#execute!" do
    it "adds all found tasks" do
      task1
      task2

      expect { result }
        .to change(WorkerPlugins::WorkplaceLink, :count).by(2)

      expect(result.fetch(:created)).to eq [task1.id, task2.id]
    end

    it "doesnt add the same resource multiple times" do
      task1 = create(:task, user:)
      task2 = create(:task, user:)
      query = User.joins(:tasks).where(id: [task1.id, task2.id])

      expect(query).to eq [user, user]
      expect { WorkerPlugins::AddQuery.execute!(query:, workplace:) }
        .to change(workplace.workplace_links, :count).by(1)
    end
  end

  describe "#ids_added_already" do
    it "returns ids of the added resources for the current workplace" do
      link1
      create(:workplace_link, resource: task2)

      task_ids = service.ids_added_already.pluck(:resource_id)
      expect(task_ids).to eq [task1.id.to_s]
    end
  end

  describe "#resources_to_add" do
    it "removes the order to fix crashes in postgres" do
      task1 = create(:task, user:)
      task2 = create(:task, user:)
      query = User.joins(:tasks).where(id: [task1.id, task2.id]).order(:name)
      service = WorkerPlugins::AddQuery.new(query:, workplace:)
      sql = service.resources_to_add.to_sql

      expect(sql).not_to include "ORDER BY"
    end
  end
end
