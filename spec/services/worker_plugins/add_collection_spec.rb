require "rails_helper"

describe WorkerPlugins::AddCollection do
  let(:task1) { create :task }
  let(:task2) { create :task }
  let(:link1) { create :workplace_link, resource: task1, workplace: workplace }
  let(:result) { WorkerPlugins::AddCollection.execute!(query: Task.all, workplace: workplace) }
  let(:service) { WorkerPlugins::AddCollection.new(query: Task.all, workplace: workplace) }
  let(:user) { create :user }
  let(:workplace) { create :workplace, user: user }

  describe "#execute!" do
    it "adds all found tasks" do
      task1
      task2

      expect { result }
        .to change(WorkerPlugins::WorkplaceLink, :count).by(2)

      expect(result.fetch(:created)).to eq("Task" => [task1.id, task2.id])
    end
  end

  describe "#ids_added_already" do
    it "returns ids of the added resources for the current workplace" do
      link1
      create(:workplace_link, resource: task2)

      task_ids = service.ids_added_already.pluck(:resource_id)
      expect(task_ids).to eq [task1.id]
    end
  end
end
