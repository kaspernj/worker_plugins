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
    it "adds all found tasks when nothing is linked yet" do
      task1
      task2

      expect { result }
        .to change(WorkerPlugins::WorkplaceLink, :count).by(2)

      expect(result.fetch(:mode)).to eq :created
      expect(result.fetch(:affected_count)).to eq 2
    end

    it "probes for unlinked candidates before running the insert" do
      # Materialize fixtures outside the capture block so only SwitchQuery's
      # own SQL is recorded.
      task1
      task2
      workplace

      queries = capture_sql_queries do
        WorkerPlugins::SwitchQuery.execute!(query: Task.all, workplace:)
      end

      probe_sql_idx = queries.find_index do |sql|
        sql =~ /\ASELECT/i && sql.include?("NOT EXISTS")
      end
      insert_sql_idx = queries.find_index do |sql|
        sql.match?(/INSERT\b.*\binto\b.*worker_plugins_workplace_links/im)
      end

      expect(probe_sql_idx).not_to be_nil, "expected a pre-insert NOT EXISTS probe; got: #{queries.inspect}"
      expect(insert_sql_idx).not_to be_nil, "expected an INSERT into worker_plugins_workplace_links; got: #{queries.inspect}"
      expect(probe_sql_idx).to be < insert_sql_idx
    end

    it "deletes all existing links when every candidate is already linked" do
      link1

      expect { result }
        .to change(WorkerPlugins::WorkplaceLink, :count).by(-1)

      expect { link1.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(result.fetch(:mode)).to eq :destroyed
      expect(result.fetch(:affected_count)).to eq 1
    end
  end
end
