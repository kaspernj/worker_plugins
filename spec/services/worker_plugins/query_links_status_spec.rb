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

    it "excludes orphaned links from checked_count" do
      task = create :task
      create(:workplace_link, workplace:, resource: task)
      # A link whose target row no longer exists — e.g. the underlying record
      # was deleted without the link being cleaned up. It must not be counted.
      orphan_task = create(:task)
      create(:workplace_link, workplace:, resource: orphan_task)
      orphan_task.destroy

      result = WorkerPlugins::QueryLinksStatus.execute!(query: Task.all, workplace:)

      expect(result.fetch(:query_count)).to eq 1
      expect(result.fetch(:checked_count)).to eq 1
      expect(result.fetch(:all_checked)).to be true
      expect(result.fetch(:some_checked)).to be false
    end
  end
end
