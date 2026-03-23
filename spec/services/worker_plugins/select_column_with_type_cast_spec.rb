require "rails_helper"

describe WorkerPlugins::SelectColumnWithTypeCast do
  describe "#execute!" do
    it "casts to varchar for non-integer compare columns" do
      compare_column = instance_double(
        ActiveRecord::ConnectionAdapters::Column,
        name: "id",
        type: nil
      )

      result = described_class.execute!(
        column_name_to_select: :id,
        column_to_compare_with: compare_column,
        query: Task.all
      )

      expect(result.to_sql).to include("CAST(tasks.id AS VARCHAR)")
    end

    it "casts to bigint for integer compare columns" do
      compare_column = instance_double(
        ActiveRecord::ConnectionAdapters::Column,
        name: "id",
        type: :integer
      )

      result = described_class.execute!(
        column_name_to_select: :resource_id,
        column_to_compare_with: compare_column,
        query: WorkerPlugins::WorkplaceLink.all
      )

      expect(result.to_sql).to include("CAST(worker_plugins_workplace_links.resource_id AS BIGINT)")
    end

    it "casts to uuid for uuid compare columns" do
      compare_column = instance_double(
        ActiveRecord::ConnectionAdapters::Column,
        name: "id",
        type: :uuid
      )

      result = described_class.execute!(
        column_name_to_select: :resource_id,
        column_to_compare_with: compare_column,
        query: WorkerPlugins::WorkplaceLink.all
      )

      expect(result.to_sql).to include("CAST(worker_plugins_workplace_links.resource_id AS UUID)")
    end
  end
end
