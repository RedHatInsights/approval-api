RSpec.xdescribe EventService do
  let(:request) { create(:request, :with_context) }
  let(:stage)   { create(:stage, :request => request) }
  subject { described_class.new(request) }

  before { allow(Group).to receive(:find) }

  it 'sends request_started event' do
    expect(subject).to receive(:send_event).with(described_class::EVENT_REQUEST_STARTED, hash_including(:request_id))
    subject.request_started
  end

  it 'sends request_finished event' do
    expect(subject).to receive(:send_event).with(described_class::EVENT_REQUEST_FINISHED, hash_including(:request_id, :decision, :reason))
    subject.request_finished
  end

  it 'sends request_canceled event' do
    expect(subject).to receive(:send_event).with(described_class::EVENT_REQUEST_CANCELED, hash_including(:request_id, :reason))
    subject.request_canceled
  end

  it 'sends approver_group_notified event' do
    expect(subject).to receive(:send_event).with(described_class::EVENT_APPROVER_GROUP_NOTIFIED, hash_including(:request_id, :group_name))
    subject.approver_group_notified(stage)
  end

  it 'sends approver_group_finished event' do
    expect(subject).to receive(:send_event).with(described_class::EVENT_APPROVER_GROUP_FINISHED, hash_including(:request_id, :group_name, :decision, :reason))
    subject.approver_group_finished(stage)
  end
end
