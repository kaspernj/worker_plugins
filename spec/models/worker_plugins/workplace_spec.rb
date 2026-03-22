require "rails_helper"

describe WorkerPlugins::Workplace do
  let(:link_task1) { create :workplace_link, resource: task1, workplace: }
  let(:link_task2) { create :workplace_link, resource: task2, workplace: }
  let!(:task1) { create :task }
  let!(:task2) { create :task }
  let(:user) { create :user }
  let(:workplace) { create :workplace, user: }

  describe "ownership validation" do
    it "is valid for a user-owned workplace" do
      expect(build(:workplace, user:, session_id: nil)).to be_valid
    end

    it "is valid for a session-owned workplace" do
      expect(build(:workplace, :for_session)).to be_valid
    end

    it "requires a user or session owner" do
      workplace = build(:workplace, user: nil, session_id: nil)

      expect(workplace).not_to be_valid
      expect(workplace.errors.full_messages).to eq(["Workplace must belong to a user or a session"])
    end

    it "rejects workplaces owned by both a user and a session" do
      workplace = build(:workplace, user:, session_id: "session-1")

      expect(workplace).not_to be_valid
      expect(workplace.errors.full_messages).to eq(["Workplace can't belong to both a user and a session"])
    end
  end

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
