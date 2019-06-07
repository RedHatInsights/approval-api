RSpec.describe RequestUpdateService do
  let(:request) { create(:request) }
  subject { described_class.new(request.id) }
  let!(:event_service) { EventService.new(request) }

  before { allow(EventService).to receive(:new).with(request).and_return(event_service) }

  context 'state becomes notified' do
    it 'sends request_started event' do
      expect(event_service).to receive(:request_started)
      subject.update(:state => Request::NOTIFIED_STATE)
      request.reload
      expect(request.state).to eq(Request::NOTIFIED_STATE)
    end
  end

  context 'state becomes finished' do
    it 'sends request_finished event' do
      expect(event_service).to receive(:request_finished)
      subject.update(:state => Request::FINISHED_STATE)
      request.reload
      expect(request.state).to eq(Request::FINISHED_STATE)
    end
  end

  context 'state becomes canceled' do
    it 'sends request_canceled event' do
      expect(event_service).to receive(:request_canceled)
      subject.update(:state => Request::CANCELED_STATE)
      request.reload
      expect(request.state).to eq(Request::CANCELED_STATE)
    end
  end

  context 'state unchanged' do
    it 'sends no events' do
      expect(event_service).not_to receive(:request_started)
      expect(event_service).not_to receive(:request_finished)
      subject.update(:requester => 'another')
      request.reload
      expect(request.requester).to eq('another')
    end
  end
end
