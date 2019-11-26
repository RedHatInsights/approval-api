RSpec.describe RequestUpdateService do
  let(:request) { create(:request) }
  subject { described_class.new(request.id) }
  let!(:event_service) { EventService.new(request) }

  before { allow(EventService).to receive(:new).with(request).and_return(event_service) }

  context 'state becomes notified' do
    it 'sends request_started event' do
      expect(event_service).to receive(:request_started)
      expect(event_service).to receive(:approver_group_notified)
      subject.update(:state => Request::STARTED_STATE)
      request.reload
      expect(request.state).to eq(Request::NOTIFIED_STATE) # automatically advance from STARTED to NOTIFIED_STATE
    end
  end

  context 'state becomes finished' do
    it 'sends request_finished event' do
      expect(event_service).to receive(:request_completed)
      expect(event_service).to receive(:approver_group_finished)
      subject.update(:state => Request::COMPLETED_STATE)
      request.reload
      expect(request.state).to eq(Request::COMPLETED_STATE)
    end
  end

  context 'state becomes canceled' do
    it 'sends request_canceled event' do
      expect(event_service).to receive(:request_canceled)
      expect(event_service).not_to receive(:approver_group_finished)
      subject.update(:state => Request::CANCELED_STATE)
      request.reload
      expect(request.state).to eq(Request::CANCELED_STATE)
    end
  end
end
