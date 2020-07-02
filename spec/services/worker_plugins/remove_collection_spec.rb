require "rails_helper"

describe WorkerPlugins::RemoveCollection do
  let(:task1) { create :task }
  let(:task2) { create :task }
  let(:link1) { create :workplace_link, resource: task1, workplace: workplace }
  let(:result) { WorkerPlugins::RemoveCollection.execute!(query: Task.all, workplace: workplace) }
  let(:service) { WorkerPlugins::RemoveCollection.new(query: Task.all, workplace: workplace) }
  let(:user) { create :user }
  let(:workplace) { create :workplace, user: user }

  describe "#execute!" do
    it "deletes all existing links and returns correct ids" do
      link1

      expect { result }
        .to change(WorkerPlugins::WorkplaceLink, :count).by(-1)

      expect { link1.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(result.fetch(:destroyed)).to eq [task1.id.to_s]
    end
  end
end
