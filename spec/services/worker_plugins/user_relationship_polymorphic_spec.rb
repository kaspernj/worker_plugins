require "rails_helper"

describe WorkerPlugins::UserRelationshipPolymorphic do
  describe ".execute!" do
    it "returns true when user_type column exists" do
      allow(WorkerPlugins::Workplace.connection).to receive(:table_exists?).and_return(true)
      allow(WorkerPlugins::Workplace).to receive(:columns_hash).and_return({"user_type" => double, "name" => double})

      expect(described_class.execute!).to be(true)
    end

    it "returns false when user_type column does not exist" do
      allow(WorkerPlugins::Workplace.connection).to receive(:table_exists?).and_return(true)
      allow(WorkerPlugins::Workplace).to receive(:columns_hash).and_return({"name" => double})

      expect(described_class.execute!).to be(false)
    end

    context "when table does not exist" do
      it "returns true without querying columns" do
        allow(WorkerPlugins::Workplace.connection).to receive(:table_exists?).and_return(false)
        allow(WorkerPlugins::Workplace).to receive(:columns_hash).and_raise(StandardError, "should not be called")

        expect(described_class.execute!).to be(true)
      end
    end
  end
end
