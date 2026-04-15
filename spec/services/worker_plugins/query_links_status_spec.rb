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
  end
end
