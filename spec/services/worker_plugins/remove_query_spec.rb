require "rails_helper"
require_relative "../../support/sql_query_counter"

describe WorkerPlugins::RemoveQuery do
  include SqlQueryCounter

  let(:task1) { create :task }
  let(:task2) { create :task }
  let(:link1) { create :workplace_link, resource: task1, workplace: }
  let(:result) { WorkerPlugins::RemoveQuery.execute!(query: Task.all, workplace:) }
  let(:service) { WorkerPlugins::RemoveQuery.new(query: Task.all, workplace:) }
  let(:user) { create :user }
  let(:workplace) { create :workplace, user: }

  describe "#execute!" do
    it "deletes all existing links and returns the affected count" do
      link1

      expect { result }
        .to change(WorkerPlugins::WorkplaceLink, :count).by(-1)

      expect { link1.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(result.fetch(:affected_count)).to eq 1
    end

    it "skips the target-model subquery when the query is unscoped" do
      link1

      queries = capture_sql_queries do
        WorkerPlugins::RemoveQuery.execute!(query: Task.all, workplace:)
      end

      delete_queries = queries.select { |sql| sql.include?("DELETE") && sql.include?("worker_plugins_workplace_links") }

      expect(delete_queries.length).to eq 1
      expect(delete_queries.first).not_to include("FROM \"tasks\"")
      expect(delete_queries.first).not_to include("FROM `tasks`")
    end

    it "keeps the subquery when the query applies WHERE scoping" do
      link1
      link2 = create(:workplace_link, resource: task2, workplace:)

      result = WorkerPlugins::RemoveQuery.execute!(query: Task.where(id: task1.id), workplace:)

      expect(result.fetch(:affected_count)).to eq 1
      expect { link1.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { link2.reload }.not_to raise_error
    end
  end
end
