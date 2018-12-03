RSpec.describe ActionCreateService do
  let(:request) { create(:request) }
  let!(:stage1) { create(:stage, :request => request) }
  let!(:stage2) { create(:stage, :request => request) }
  let(:svc1)    { described_class.new(stage1.id) }
  let(:svc2)    { described_class.new(stage2.id) }
  let!(:event_service) { EventService.new(request) }

  before do
    allow(EventService).to  receive(:new).with(request).and_return(event_service)
    allow(event_service).to receive(:request_started)
    allow(event_service).to receive(:request_finished)
    allow(event_service).to receive(:approver_group_notified)
    allow(event_service).to receive(:approver_group_finished)
  end

  context 'notify operation' do
    it 'updates stage and request' do
      action = svc1.create(:operation => Action::NOTIFY_OPERATION, :processed_by => 'system')
      stage1.reload
      request.reload
      expect(action).to have_attributes(:operation => Action::NOTIFY_OPERATION, :processed_by => 'system')
      expect(stage1.state).to  eq(Stage::NOTIFIED_STATE)
      expect(request.state).to eq(Request::NOTIFIED_STATE)
    end
  end

  context 'approve/deny operation' do
    it 'updates current stage' do
      action = svc1.create(:operation => Action::APPROVE_OPERATION, :processed_by => 'man')
      stage1.reload
      request.reload
      expect(action).to  have_attributes(:operation => Action::APPROVE_OPERATION, :processed_by => 'man')
      expect(stage1).to  have_attributes(:state => Stage::FINISHED_STATE, :decision => Stage::APPROVED_STATUS)
      expect(request).to have_attributes(:state => Stage::PENDING_STATE,  :decision => Stage::UNDECIDED_STATUS)
    end

    it 'updates current stage and overall request' do
      action = svc2.create(:operation => Action::DENY_OPERATION, :processed_by => 'man', :comments => 'bad')
      stage2.reload
      request.reload
      expect(action).to  have_attributes(:operation => Action::DENY_OPERATION, :processed_by => 'man', :comments => 'bad')
      expect(stage2).to  have_attributes(:state => Stage::FINISHED_STATE, :decision => Stage::DENIED_STATUS, :reason => 'bad')
      expect(request).to have_attributes(:state => Stage::FINISHED_STATE, :decision => Stage::DENIED_STATUS, :reason => 'bad')
    end
  end

  context 'skip operation' do
    it 'updates stage and request' do
      action1 = svc1.create(:operation => Action::DENY_OPERATION, :processed_by => 'man', :comments => 'bad')
      action2 = svc2.create(:operation => Action::SKIP_OPERATION, :processed_by => 'sys', :comments => 'nop')
      stage1.reload
      stage2.reload
      request.reload
      expect(action1).to  have_attributes(:operation => Action::DENY_OPERATION, :processed_by => 'man', :comments => 'bad')
      expect(action2).to  have_attributes(:operation => Action::SKIP_OPERATION, :processed_by => 'sys', :comments => 'nop')
      expect(stage1).to  have_attributes(:state => Stage::FINISHED_STATE, :decision => Stage::DENIED_STATUS, :reason => 'bad')
      expect(stage2).to  have_attributes(:state => Stage::SKIPPED_STATE,  :decision => Stage::UNDECIDED_STATUS, :reason => nil)
      expect(request).to have_attributes(:state => Stage::FINISHED_STATE, :decision => Stage::DENIED_STATUS, :reason => 'bad')
    end
  end

  context 'memo operation' do
    it 'creates a new action only' do
      action = svc1.create(:operation => Action::MEMO_OPERATION, :processed_by => 'man', :comments => 'later')
      stage1.reload
      request.reload
      expect(action).to  have_attributes(:operation => Action::MEMO_OPERATION, :processed_by => 'man', :comments => 'later')
      expect(stage1).to  have_attributes(:state => Stage::PENDING_STATE, :decision => Stage::UNDECIDED_STATUS)
      expect(request).to have_attributes(:state => Stage::PENDING_STATE, :decision => Stage::UNDECIDED_STATUS)
    end
  end
end
