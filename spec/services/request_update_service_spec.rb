RSpec.describe RequestUpdateService do
  let(:request) { create(:request, :with_tenant) }
  subject { described_class.new(request.id) }
  let!(:event_service) { EventService.new(request) }
  let(:group) { instance_double(Group, :name => 'group1', :has_role? => true, :users => ['user']) }

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

  context 'state becomes failed' do
    it 'sends request_finished event' do
      expect(event_service).to receive(:request_completed)
      expect(event_service).to receive(:approver_group_finished)
      subject.update(:state => Request::FAILED_STATE)
      request.reload
      expect(request.state).to eq(Request::FAILED_STATE)
    end
  end

  describe '#runtime_validate_group' do
    before { allow(subject).to receive(:ensure_group).and_return(group) }

    context 'with approver role' do
      it 'passes the validation' do
        expect(subject.runtime_validate_group(request)).to be_truthy
        request.reload
        expect(request.actions.count).to eq(0)
      end
    end

    context 'without approver role' do
      let(:msg) { "Group #{group.name} does not have approver role" }

      it 'returns false' do
        allow(group).to receive(:has_role?).and_return(false)

        expect(request.actions.count).to eq(0)
        expect(subject.runtime_validate_group(request)).to be_falsey
        request.reload
        expect(request.actions.count).to eq(1)
        expect(request.actions.first.comments).to eq(msg)
        expect(request.state).to eq(Request::FAILED_STATE)
      end
    end

    context 'without users' do
      let(:msg) { "Group #{group.name} is empty" }

      it 'returns false' do
        allow(group).to receive(:users).and_return([])

        expect(request.actions.count).to eq(0)
        expect(subject.runtime_validate_group(request)).to be_falsey
        request.reload
        expect(request.actions.count).to eq(1)
        expect(request.actions.first.comments).to eq(msg)
        expect(request.state).to eq(Request::FAILED_STATE)
      end
    end
  end
end
