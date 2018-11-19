RSpec.describe EventService do
  let(:request) { create(:request) }
  let(:stage)   { create(:stage, :request => request) }
  subject { described_class.new(request) }

  it 'sends request_started event' do
    expect(subject).to receive(:send_event).with(described_class::EVENT_REQUEST_STARTED, hash_including(:request_id))
    subject.request_started
  end

  it 'sends request_finished event' do
    expect(subject).to receive(:send_event).with(described_class::EVENT_REQUEST_FINISHED, hash_including(:request_id, :decision, :comments))
    subject.request_finished
  end

  it 'sends approver_group_notified event' do
    expect(subject).to receive(:send_event).with(described_class::EVENT_APPROVER_GROUP_NOTIFIED, hash_including(:request_id, :group_name))
    subject.approver_group_notified(stage)
  end

  it 'sends approver_group_finished event' do
    expect(subject).to receive(:send_event).with(described_class::EVENT_APPROVER_GROUP_FINISHED, hash_including(:request_id, :group_name, :decision, :comments))
    subject.approver_group_finished(stage)
  end
end
