require "rails_helper"
require_relative "../../support/sql_query_counter"

describe WorkerPlugins::QueryLinksStatus do
  include SqlQueryCounter

  let(:user) { create :user }
  let(:workplace) { create :workplace, user: }

  describe "#execute!" do
    it "only counts checked links for the queried resource type" do
      task = create :task

      create :workplace_link, workplace:, resource: user

      result = WorkerPlugins::QueryLinksStatus.execute!(query: Task.where(id: task.id), workplace:)

      expect(result).to eq(
        all_checked: false,
        checked_count: 0,
        query_count: 1,
        some_checked: false
      )
    end

    it "skips the target-model subquery when counting checked links for an unscoped query" do
      task = create :task
      create(:workplace_link, workplace:, resource: task)

      queries = capture_sql_queries do
        WorkerPlugins::QueryLinksStatus.execute!(query: Task.all, workplace:)
      end

      checked_count_queries = queries.select do |sql|
        sql.include?("SELECT COUNT(*)") && sql.include?("worker_plugins_workplace_links")
      end

      expect(checked_count_queries.length).to eq 1
      expect(checked_count_queries.first).not_to include("FROM \"tasks\"")
      expect(checked_count_queries.first).not_to include("FROM `tasks`")
    end

    it "keeps the subquery when the query is scoped with .from" do
      task = create :task
      other_task = create :task
      create(:workplace_link, workplace:, resource: task)
      create(:workplace_link, workplace:, resource: other_task)

      from_query = Task.from(Task.where(id: task.id), :tasks)

      result = WorkerPlugins::QueryLinksStatus.execute!(query: from_query, workplace:)

      expect(result.fetch(:checked_count)).to eq 1
      expect(result.fetch(:query_count)).to eq 1
      expect(result.fetch(:all_checked)).to be true
    end
  end
end
