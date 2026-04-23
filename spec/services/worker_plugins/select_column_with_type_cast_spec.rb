require "rails_helper"

describe WorkerPlugins::SelectColumnWithTypeCast do
  describe "#execute!" do
    it "casts to varchar for non-integer compare columns on non-mysql adapters" do
      compare_column = instance_double(
        ActiveRecord::ConnectionAdapters::Column,
        name: "id",
        type: nil
      )
      allow_any_instance_of(described_class).to receive(:mysql?).and_return(false)

      result = described_class.execute!(
        column_name_to_select: :id,
        column_to_compare_with: compare_column,
        query: Task.all
      )

      expect(result.to_sql).to include("CAST(tasks.id AS VARCHAR)")
    end

    it "casts to char for non-integer compare columns on mysql adapters" do
      compare_column = instance_double(
        ActiveRecord::ConnectionAdapters::Column,
        name: "id",
        type: nil
      )
      allow_any_instance_of(described_class).to receive(:mysql?).and_return(true)

      result = described_class.execute!(
        column_name_to_select: :id,
        column_to_compare_with: compare_column,
        query: Task.all
      )

      expect(result.to_sql).to include("CAST(tasks.id AS CHAR)")
    end

    it "casts to bigint for integer compare columns on non-mysql adapters" do
      compare_column = instance_double(
        ActiveRecord::ConnectionAdapters::Column,
        name: "id",
        type: :integer
      )
      allow_any_instance_of(described_class).to receive(:mysql?).and_return(false)

      result = described_class.execute!(
        column_name_to_select: :resource_id,
        column_to_compare_with: compare_column,
        query: WorkerPlugins::WorkplaceLink.all
      )

      expect(result.to_sql).to include("CAST(worker_plugins_workplace_links.resource_id AS BIGINT)")
    end

    it "casts to signed for integer compare columns on mysql adapters" do
      compare_column = instance_double(
        ActiveRecord::ConnectionAdapters::Column,
        name: "id",
        type: :integer
      )
      allow_any_instance_of(described_class).to receive(:mysql?).and_return(true)

      result = described_class.execute!(
        column_name_to_select: :resource_id,
        column_to_compare_with: compare_column,
        query: WorkerPlugins::WorkplaceLink.all
      )

      expect(result.to_sql).to include("CAST(worker_plugins_workplace_links.resource_id AS SIGNED)")
    end

    it "casts to uuid for uuid compare columns" do
      compare_column = instance_double(
        ActiveRecord::ConnectionAdapters::Column,
        name: "id",
        type: :uuid
      )
      allow_any_instance_of(described_class).to receive(:postgres?).and_return(true)
      allow_any_instance_of(described_class).to receive(:mysql?).and_return(false)

      result = described_class.execute!(
        column_name_to_select: :resource_id,
        column_to_compare_with: compare_column,
        query: WorkerPlugins::WorkplaceLink.all
      )

      expect(result.to_sql).to include("CAST(worker_plugins_workplace_links.resource_id AS UUID)")
    end

    it "casts uuid compare columns to varchar on non-postgres adapters" do
      compare_column = instance_double(
        ActiveRecord::ConnectionAdapters::Column,
        name: "id",
        type: :uuid
      )
      allow_any_instance_of(described_class).to receive(:postgres?).and_return(false)
      allow_any_instance_of(described_class).to receive(:mysql?).and_return(false)

      result = described_class.execute!(
        column_name_to_select: :resource_id,
        column_to_compare_with: compare_column,
        query: WorkerPlugins::WorkplaceLink.all
      )

      expect(result.to_sql).to include("CAST(worker_plugins_workplace_links.resource_id AS VARCHAR)")
    end

    it "casts uuid compare columns to char on mysql adapters when the selected column is not string-like" do
      compare_column = instance_double(
        ActiveRecord::ConnectionAdapters::Column,
        name: "id",
        type: :uuid
      )
      allow_any_instance_of(described_class).to receive(:postgres?).and_return(false)
      allow_any_instance_of(described_class).to receive(:mysql?).and_return(true)

      result = described_class.execute!(
        column_name_to_select: :id,
        column_to_compare_with: compare_column,
        query: Task.all
      )

      expect(result.to_sql).to include("CAST(tasks.id AS CHAR)")
    end

    it "does not cast between string and uuid columns on mysql adapters" do
      compare_column = instance_double(
        ActiveRecord::ConnectionAdapters::Column,
        name: "id",
        type: :uuid
      )
      allow_any_instance_of(described_class).to receive(:postgres?).and_return(false)
      allow_any_instance_of(described_class).to receive(:mysql?).and_return(true)

      result = described_class.execute!(
        column_name_to_select: :resource_id,
        column_to_compare_with: compare_column,
        query: WorkerPlugins::WorkplaceLink.all
      )

      expect(result.to_sql).to include("resource_id")
      expect(result.to_sql).not_to include("CAST(")
    end

    it "does not cast on mysql when the selected column has an unknown type against a string compare column" do
      # Covers MariaDB's native UUID type, which older mysql2 adapters surface
      # as an unknown (nil) type rather than :uuid or :string.
      compare_column = instance_double(
        ActiveRecord::ConnectionAdapters::Column,
        name: "resource_id",
        type: :string
      )
      select_column = instance_double(
        ActiveRecord::ConnectionAdapters::Column,
        name: "id",
        type: nil
      )
      allow(User).to receive(:column_for_attribute).with(:id).and_return(select_column)
      allow_any_instance_of(described_class).to receive(:postgres?).and_return(false)
      allow_any_instance_of(described_class).to receive(:mysql?).and_return(true)

      result = described_class.execute!(
        column_name_to_select: :id,
        column_to_compare_with: compare_column,
        query: User.all
      )

      expect(result.to_sql).not_to include("CAST(")
    end
  end
end
