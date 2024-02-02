require "rails_helper"

describe WorkerPlugins::WorkplaceLink do
  let(:task) { create :task }
  let(:workplace) { create :workplace }
  let(:workplace_link) { create :workplace_link, resource: task, workplace: }

  it "validates uniqueness to the resource and workplace" do
    workplace_link
    another_link = WorkerPlugins::WorkplaceLink.new(resource: task, workplace:)

    expect(another_link).not_to be_valid
    expect(another_link.errors.full_messages).to eq ["Resource ID has already been taken"]
  end
end
