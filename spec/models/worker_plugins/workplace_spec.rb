require "rails_helper"
require_relative "../../support/sql_query_counter"

describe WorkerPlugins::Workplace do
  include SqlQueryCounter

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

    it "loads streamed resources without one query per link" do
      link_task1
      link_task2

      queries = capture_sql_queries do
        workplace.each_resource(types: ["Task"]) { |_task| nil }
      end

      select_queries = queries.grep(/\ASELECT/i)

      expect(select_queries.length).to eq 2
    end

    it "skips stale links whose resource has been deleted" do
      link_task1
      link_task2.destroy!

      found_links = []
      workplace.each_resource(types: ["Task"]) do |task|
        found_links << task
      end

      expect(found_links).to eq [task1]
    end
  end

  describe "#each_query_for_resources" do
    it "groups resource ids without re-querying ids per resource type" do
      create :workplace_link, workplace:, resource: task1
      create :workplace_link, workplace:, resource: user

      queries = capture_sql_queries do
        workplace.each_query_for_resources { |query:, resource_type:| [query, resource_type] }
      end

      select_queries = queries.grep(/\ASELECT/i)

      expect(select_queries.length).to eq 1
    end
  end
end
