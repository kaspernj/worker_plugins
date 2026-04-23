require "rails_helper"
require_relative "../../support/sql_query_counter"

describe WorkerPlugins::SwitchQuery do
  include SqlQueryCounter

  let(:task1) { create :task }
  let(:task2) { create :task }
  let(:link1) { create :workplace_link, resource: task1, workplace: }
  let(:result) { WorkerPlugins::SwitchQuery.execute!(query: Task.all, workplace:) }
  let(:service) { WorkerPlugins::SwitchQuery.new(query: Task.all, workplace:) }
  let(:user) { create :user }
  let(:workplace) { create :workplace, user: }

  describe "#execute!" do
    it "adds all found tasks" do
      task1
      task2

      expect { result }
        .to change(WorkerPlugins::WorkplaceLink, :count).by(2)

      expect(result.fetch(:mode)).to eq :created
      expect(result.fetch(:created)).to contain_exactly(task1.id, task2.id)
    end

    it "only touches both tables in a single cross-table statement" do
      task1
      task2

      queries = capture_sql_queries do
        WorkerPlugins::SwitchQuery.execute!(query: Task.all, workplace:)
      end

      cross_table_queries = queries.select do |sql|
        sql.include?("tasks") &&
          sql.include?("worker_plugins_workplace_links")
      end

      expect(cross_table_queries.length).to eq 1
      expect(cross_table_queries.first).to match(/INSERT\b.*\bINTO\b/im)
    end

    it "deletes all existing links and returns correct ids" do
      link1

      expect { result }
        .to change(WorkerPlugins::WorkplaceLink, :count).by(-1)

      expect { link1.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(result.fetch(:mode)).to eq :destroyed
      expect(result.fetch(:destroyed)).to eq [task1.id.to_s]
    end
  end
end
