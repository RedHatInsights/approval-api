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

  describe '#send_event' do
    let(:headers) { request.context['headers'] }
    let(:open_args) { {:protocol => 'Kafka', :host => 'khost', :port => '9092', :encoding => 'json'} }
    let(:publish_args) { }
    let(:test_env) do
      {:QUEUE_HOST => 'khost', :QUEUE_PORT => '9092', :QUEUE_NAME => 'platform.approval'}
    end

    shared_examples_for '#test_send_event' do
      it 'sends event through messaging client' do
        RequestSpecHelper.with_modified_env(test_env) do
          client_mock = double.as_null_object
          allow(ManageIQ::Messaging::Client).to receive(:open).with(open_args).and_yield(client_mock)
          expect(client_mock).to receive(:publish_topic).with(:service => 'platform.approval',
                                                              :sender  => described_class::EVENT_SENDER,
                                                              :event   => 'event',
                                                              :payload => 'payload',
                                                              :headers => headers)
          object.send(:send_event, 'event', 'payload')
        end
      end
    end

    context 'with request' do
      let(:object) { subject }

      it_behaves_like "#test_send_event"
    end

    context 'without request' do
      let(:object) { described_class.new }
      let(:headers) { RequestSpecHelper.default_request_hash['headers'] }

      around do |example|
        Insights::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) do
          example.call
        end
      end

      it_behaves_like "#test_send_event"
    end
  end
end
