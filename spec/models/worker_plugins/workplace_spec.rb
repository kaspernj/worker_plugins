require "rails_helper"

describe WorkerPlugins::Workplace do
  let!(:task1) { create :task }
  let!(:task2) { create :task }
  let(:user) { create :user }
  let(:workplace) { create :workplace, user: user }

  describe "#add_links_to_objects" do
    it "takes a collection and creates links for those models" do
      tasks = Task.all

      expect { workplace.add_links_to_objects(tasks) }
        .to change(WorkerPlugins::WorkplaceLink, :count).by(2)
    end
  end
end
