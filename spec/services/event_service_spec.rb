RSpec.describe EventService do
  let(:request) { create(:request, :with_context) }
  subject { described_class.new(request) }

  it 'sends request_started event' do
    expect(subject).to receive(:send_event).with(described_class::EVENT_REQUEST_STARTED, hash_including(:request_id))
    subject.request_started
  end

  it 'sends request_finished event' do
    expect(subject).to receive(:send_event).with(described_class::EVENT_REQUEST_COMPLETED, hash_including(:request_id, :decision, :reason))
    subject.request_completed
  end

  it 'sends request_canceled event' do
    expect(subject).to receive(:send_event).with(described_class::EVENT_REQUEST_CANCELED, hash_including(:request_id, :reason))
    subject.request_canceled
  end

  it 'sends approver_group_notified event' do
    expect(subject).to receive(:send_event).with(described_class::EVENT_APPROVER_GROUP_NOTIFIED, hash_including(:request_id, :group_name))
    subject.approver_group_notified
  end

  it 'sends approver_group_finished event' do
    expect(subject).to receive(:send_event).with(described_class::EVENT_APPROVER_GROUP_FINISHED, hash_including(:request_id, :group_name, :decision, :reason))
    subject.approver_group_finished
  end

  it 'sends workflow_deleted event' do
    expect(subject).to receive(:send_event).with(described_class::EVENT_WORKFLOW_DELETED, hash_including(:workflow_id))
    subject.workflow_deleted(1)
  end
end
