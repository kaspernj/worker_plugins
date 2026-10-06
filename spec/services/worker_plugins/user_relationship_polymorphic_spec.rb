require "rails_helper"

describe WorkerPlugins::UserRelationshipPolymorphic do
  describe ".execute!" do
    it "returns true when user_type column exists" do
      allow(WorkerPlugins::Workplace).to receive(:columns_hash).and_return({"user_type" => double, "name" => double})

      expect(described_class.execute!).to be(true)
    end

    it "returns false when user_type column does not exist" do
      allow(WorkerPlugins::Workplace).to receive(:columns_hash).and_return({"name" => double})

      expect(described_class.execute!).to be(false)
    end

    context "when table does not exist" do
      it "returns true for MySQL error" do
        error = StandardError.new("Table 'worker_plugins_workplaces' doesn't exist")
        allow(WorkerPlugins::Workplace).to receive(:columns_hash).and_raise(error)

        expect(described_class.execute!).to be(true)
      end

      it "returns true for SQLite error" do
        error = StandardError.new("Could not find table 'worker_plugins_workplaces'")
        allow(WorkerPlugins::Workplace).to receive(:columns_hash).and_raise(error)

        expect(described_class.execute!).to be(true)
      end

      it "returns true for PostgreSQL error" do
        error = StandardError.new('relation "worker_plugins_workplaces" does not exist')
        allow(WorkerPlugins::Workplace).to receive(:columns_hash).and_raise(error)

        expect(described_class.execute!).to be(true)
      end
    end

    it "re-raises unrelated errors" do
      error = StandardError.new("some other error")
      allow(WorkerPlugins::Workplace).to receive(:columns_hash).and_raise(error)

      expect { described_class.execute! }.to raise_error(StandardError, "some other error")
    end
  end
end
