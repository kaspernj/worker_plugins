require "rails_helper"

describe WorkerPlugins::DeleteOldWorkplaces do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create :user }

  describe "#execute!" do
    it "deletes workplaces with no link activity since the cutoff" do
      stale_workplace = travel_to(3.months.ago) { create(:workplace, user:) }

      result = WorkerPlugins::DeleteOldWorkplaces.execute!(older_than: 2.months)

      expect(result.fetch(:workplaces_deleted)).to eq 1
      expect { stale_workplace.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "keeps workplaces that were updated inside the window" do
      recent_workplace = travel_to(1.week.ago) { create(:workplace, user:) }

      WorkerPlugins::DeleteOldWorkplaces.execute!(older_than: 2.months)

      expect { recent_workplace.reload }.not_to raise_error
    end

    it "keeps workplaces with recent link activity even if the workplace row itself is old" do
      workplace = travel_to(3.months.ago) { create(:workplace, user:) }
      task = create :task
      link = travel_to(1.week.ago) { create(:workplace_link, workplace:, resource: task) }

      WorkerPlugins::DeleteOldWorkplaces.execute!(older_than: 2.months)

      expect { workplace.reload }.not_to raise_error
      expect { link.reload }.not_to raise_error
    end

    it "removes links belonging to deleted workplaces" do
      stale_workplace = nil
      stale_link = nil
      task = create :task

      travel_to(3.months.ago) do
        stale_workplace = create(:workplace, user:)
        stale_link = create(:workplace_link, workplace: stale_workplace, resource: task)
      end

      result = WorkerPlugins::DeleteOldWorkplaces.execute!(older_than: 2.months)

      expect(result.fetch(:workplaces_deleted)).to eq 1
      expect(result.fetch(:links_deleted)).to eq 1
      expect { stale_workplace.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { stale_link.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "processes batches of the requested size" do
      travel_to(3.months.ago) do
        create_list(:workplace, 3, user:)
      end

      result = WorkerPlugins::DeleteOldWorkplaces.execute!(older_than: 2.months, batch_size: 2)

      expect(result.fetch(:workplaces_deleted)).to eq 3
    end
  end
end
