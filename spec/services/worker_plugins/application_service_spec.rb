require "rails_helper"

describe WorkerPlugins::ApplicationService do
  describe "#mysql?" do
    let(:service_class) do
      Class.new(WorkerPlugins::ApplicationService) do
        def perform
          succeed! mysql?
        end
      end
    end

    it "returns true for mysql adapters" do
      allow(ActiveRecord::Base.connection).to receive(:instance_values).and_return({"config" => {adapter: "mysql2"}})

      result = service_class.execute!

      expect(result).to be(true)
    end

    it "returns true for trilogy adapters" do
      allow(ActiveRecord::Base.connection).to receive(:instance_values).and_return({"config" => {adapter: "trilogy"}})

      result = service_class.execute!

      expect(result).to be(true)
    end

    it "returns false for non-mysql adapters" do
      allow(ActiveRecord::Base.connection).to receive(:instance_values).and_return({"config" => {adapter: "postgresql"}})

      result = service_class.execute!

      expect(result).to be(false)
    end
  end
end
