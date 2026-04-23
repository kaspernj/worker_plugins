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

    it "reports checked_count equal to query_count when every live row is linked (unscoped)" do
      task1 = create :task
      task2 = create :task
      create(:workplace_link, workplace:, resource: task1)
      create(:workplace_link, workplace:, resource: task2)

      result = WorkerPlugins::QueryLinksStatus.execute!(query: Task.all, workplace:)

      expect(result.fetch(:query_count)).to eq 2
      expect(result.fetch(:checked_count)).to eq 2
      expect(result.fetch(:all_checked)).to be true
      expect(result.fetch(:some_checked)).to be false
    end

    it "uses an index-only count on the links table for unscoped queries (no cross-table lookup)" do
      task = create :task
      create(:workplace_link, workplace:, resource: task)

      queries = capture_sql_queries do
        WorkerPlugins::QueryLinksStatus.execute!(query: Task.all, workplace:)
      end

      link_count_queries = queries.select do |sql|
        sql.include?("SELECT COUNT(*)") && sql.include?("worker_plugins_workplace_links")
      end

      expect(link_count_queries.length).to eq 1
      # The cheap path must not reach into the target table at all — that's
      # the entire point, since joining against 340k+ rows is ~200× slower
      # than the index-only count.
      expect(link_count_queries.first).not_to match(/FROM [`"]?tasks[`"]?/i)
      expect(link_count_queries.first).not_to include("INNER JOIN")
      expect(link_count_queries.first).not_to include("DISTINCT")
    end

    it "clamps checked_count to query_count when orphan links exist (unscoped)" do
      task = create :task
      create(:workplace_link, workplace:, resource: task)
      # Create a link whose target row is destroyed right after — simulates
      # an orphan that accumulated between DeleteOrphanLinks runs.
      orphan_task = create :task
      create(:workplace_link, workplace:, resource: orphan_task)
      orphan_task.destroy

      result = WorkerPlugins::QueryLinksStatus.execute!(query: Task.all, workplace:)

      # query_count is 1 (only the live task). The raw link count is 2 (live +
      # orphan). The clamp should pin checked_count to query_count so
      # all_checked stays correct.
      expect(result.fetch(:query_count)).to eq 1
      expect(result.fetch(:checked_count)).to eq 1
      expect(result.fetch(:all_checked)).to be true
      expect(result.fetch(:some_checked)).to be false
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
