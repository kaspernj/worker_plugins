require "rails_helper"

describe WorkerPlugins::DeleteOrphanLinks do
  let(:user) { create :user }
  let(:workplace) { create :workplace, user: }

  describe "#execute!" do
    it "deletes links whose target row has been destroyed" do
      task = create :task
      link = create(:workplace_link, workplace:, resource: task)
      Task.where(id: task.id).delete_all # skip dependent callbacks

      result = WorkerPlugins::DeleteOrphanLinks.execute!

      expect(result.fetch(:deleted_count)).to eq 1
      expect { link.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "keeps links whose target row still exists" do
      task = create :task
      link = create(:workplace_link, workplace:, resource: task)

      result = WorkerPlugins::DeleteOrphanLinks.execute!

      expect(result.fetch(:deleted_count)).to eq 0
      expect { link.reload }.not_to raise_error
    end

    it "leaves links alone when the resource_type doesn't resolve to a Ruby class" do
      # Links pointing at renamed / removed models can legitimately exist in
      # old databases; cleaning those up requires human judgement, so the
      # service skips any resource_type whose class cannot be resolved.
      service = described_class.new
      allow(service).to receive(:distinct_resource_types).and_return(["NotARealModelClass"])
      expect(WorkerPlugins::WorkplaceLink).not_to receive(:where)

      expect(service.execute!.fetch(:deleted_count)).to eq 0
    end

    it "sweeps orphans across multiple resource types in one run" do
      live_task = create :task
      orphan_task = create :task
      orphan_user = create :user
      live_task_link = create(:workplace_link, workplace:, resource: live_task)
      orphan_task_link = create(:workplace_link, workplace:, resource: orphan_task)
      orphan_user_link = create(:workplace_link, workplace:, resource: orphan_user)
      Task.where(id: orphan_task.id).delete_all
      User.where(id: orphan_user.id).delete_all

      result = WorkerPlugins::DeleteOrphanLinks.execute!

      expect(result.fetch(:deleted_count)).to eq 2
      expect { live_task_link.reload }.not_to raise_error
      expect { orphan_task_link.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { orphan_user_link.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
