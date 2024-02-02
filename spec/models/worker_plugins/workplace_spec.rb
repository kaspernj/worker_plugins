require "rails_helper"

describe WorkerPlugins::Workplace do
  let(:link_task1) { create :workplace_link, resource: task1, workplace: }
  let(:link_task2) { create :workplace_link, resource: task2, workplace: }
  let!(:task1) { create :task }
  let!(:task2) { create :task }
  let(:user) { create :user }
  let(:workplace) { create :workplace, user: }

  describe "#each_resource" do
    it "streams resources of the given type" do
      link_task1
      link_task2

      found_links = []
      workplace.each_resource(types: ["Task"]) do |task|
        found_links << task
      end

      expect(found_links.length).to eq 2
      expect(found_links).to eq [task1, task2]
    end
  end
end
