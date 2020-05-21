RSpec.describe ActionCreateService do
  let(:request) { create(:request, :with_context) }
  let!(:child1) { request.create_child }
  let!(:child2) { request.create_child }
  let(:svc)     { described_class.new(request.id) }
  let(:svc1)    { described_class.new(child1.id)  }
  let(:svc2)    { described_class.new(child2.id)  }
  let!(:event_service) { EventService.new(request) }

  before do
    allow(EventService).to  receive(:new).with(request).and_return(event_service)
    allow(EventService).to  receive(:new).with(child1).and_return(event_service)
    allow(EventService).to  receive(:new).with(child2).and_return(event_service)
    allow(event_service).to receive(:request_started)
    allow(event_service).to receive(:request_completed)
    allow(event_service).to receive(:request_canceled)
    allow(event_service).to receive(:approver_group_notified)
    allow(event_service).to receive(:approver_group_finished)
  end

  around do |example|
    Insights::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) do
      example.call
    end
  end

  context 'notify operation' do
    it 'updates child and parent requests' do
      action = svc1.create('operation' => Action::START_OPERATION, 'processed_by' => 'system')
      child1.reload
      request.reload
      expect(action).to have_attributes(:operation => Action::START_OPERATION, :processed_by => 'system')
      expect(child1.state).to eq(Request::NOTIFIED_STATE)
    end
  end

  context 'approve/deny operation' do
    it 'updates current child request' do
      child1.update(:state => Request::NOTIFIED_STATE)
      action = svc1.create('operation' => Action::APPROVE_OPERATION, 'processed_by' => 'man')
      child1.reload
      request.reload
      expect(action).to  have_attributes(:operation => Action::APPROVE_OPERATION, :processed_by => 'man')
      expect(child1).to  have_attributes(:state => Request::COMPLETED_STATE, :decision => Request::APPROVED_STATUS)
      expect(request).to have_attributes(:state => Request::PENDING_STATE,   :decision => Request::UNDECIDED_STATUS)
    end

    it 'updates current child and parent requests' do
      child2.update(:state => Request::NOTIFIED_STATE)
      action = svc2.create('operation' => Action::DENY_OPERATION, 'processed_by' => 'man', 'comments' => 'bad')
      child2.reload
      request.reload
      expect(action).to  have_attributes(:operation => Action::DENY_OPERATION, :processed_by => 'man', :comments => 'bad')
      expect(child2).to  have_attributes(:state => Request::COMPLETED_STATE,   :decision => Request::DENIED_STATUS, :reason => 'bad')
      expect(request).to have_attributes(:state => Request::COMPLETED_STATE,   :decision => Request::DENIED_STATUS, :reason => 'bad')
    end

    it 'raises an error when approve on parent request' do
      expect { svc.create('operation' => Action::APPROVE_OPERATION, 'processed_by' => 'man') }.to raise_error(Exceptions::InvalidStateTransitionError)
    end

    it 'raises an error when deny on parent request' do
      expect { svc.create('operation' => Action::DENY_OPERATION, 'processed_by' => 'man') }.to raise_error(Exceptions::InvalidStateTransitionError)
    end
  end

  context 'error operation' do
    it 'updates both leaf and root requests' do
      action = svc1.create('operation' => Action::ERROR_OPERATION, 'processed_by' => 'man', 'comments' => 'something is wrong')
      child1.reload
      child2.reload
      request.reload
      expect(action).to  have_attributes(:operation => Action::ERROR_OPERATION, :processed_by => 'man')
      expect(child1).to  have_attributes(:state => Request::FAILED_STATE,  :decision => Request::ERROR_STATUS)
      expect(child2).to  have_attributes(:state => Request::SKIPPED_STATE, :decision => Request::UNDECIDED_STATUS)
      expect(request).to have_attributes(:state => Request::FAILED_STATE,  :decision => Request::ERROR_STATUS)
    end

    it 'raises an error when error on parent request' do
      expect { svc.create('operation' => Action::ERROR_OPERATION, 'processed_by' => 'man', 'comments' => 'bad') }.to raise_error(Exceptions::InvalidStateTransitionError)
    end

    it 'raises an error when no reason is given' do
      expect { svc1.create('operation' => Action::ERROR_OPERATION, 'processed_by' => 'man') }.to raise_error(Exceptions::UserError)
    end

    it 'raises an error when the request has already finished' do
      child1.update(:state => Request::COMPLETED_STATE)
      expect { svc1.create('operation' => Action::ERROR_OPERATION, 'processed_by' => 'man') }.to raise_error(Exceptions::InvalidStateTransitionError)
    end
  end

  context 'skip operation' do
    it 'updates both children and parent requests' do
      child1.update(:state => Request::NOTIFIED_STATE)
      action1 = svc1.create('operation' => Action::DENY_OPERATION, 'processed_by' => 'man', 'comments' => 'bad')
      child1.reload
      child2.reload
      request.reload
      expect(action1).to have_attributes(:operation => Action::DENY_OPERATION, :processed_by => 'man', :comments => 'bad')
      expect(child1).to  have_attributes(:state => Request::COMPLETED_STATE,   :decision => Request::DENIED_STATUS,    :reason => 'bad')
      expect(child2).to  have_attributes(:state => Request::SKIPPED_STATE,     :decision => Request::UNDECIDED_STATUS, :reason => nil)
      expect(request).to have_attributes(:state => Request::COMPLETED_STATE,   :decision => Request::DENIED_STATUS,    :reason => 'bad')
    end
  end

  context 'cancel operation' do
    it 'updates child and parent requests' do
      request.update(:state => Request::NOTIFIED_STATE)
      action = svc.create('operation' => Action::CANCEL_OPERATION, 'processed_by' => 'requester', 'comments' => 'regret')
      child1.reload
      child2.reload
      request.reload
      expect(action).to  have_attributes(:operation => Action::CANCEL_OPERATION, :processed_by => 'requester', :comments => 'regret')
      expect(child1).to  have_attributes(:state => Request::SKIPPED_STATE,       :decision => Request::UNDECIDED_STATUS, :reason => nil)
      expect(child2).to  have_attributes(:state => Request::SKIPPED_STATE,       :decision => Request::UNDECIDED_STATUS, :reason => nil)
      expect(request).to have_attributes(:state => Request::CANCELED_STATE,      :decision => Request::CANCELED_STATUS,  :reason => 'regret')
    end

    it 'raises an error when cancel on child request' do
      expect { svc1.create('operation' => Action::CANCEL_OPERATION, 'processed_by' => 'man') }.to raise_error(Exceptions::InvalidStateTransitionError)
    end
  end

  context 'memo operation' do
    it 'creates a new action only' do
      action = svc1.create('operation' => Action::MEMO_OPERATION, 'processed_by' => 'man', 'comments' => 'later')
      child1.reload
      request.reload
      expect(action).to  have_attributes(:operation => Action::MEMO_OPERATION, :processed_by => 'man', :comments => 'later')
      expect(child1).to  have_attributes(:state => Request::PENDING_STATE,     :decision => Request::UNDECIDED_STATUS)
      expect(request).to have_attributes(:state => Request::PENDING_STATE,     :decision => Request::UNDECIDED_STATUS)
    end
  end

  context 'auto set processed_by if nil' do
    it 'create a new action with nil processed_by' do
      action = svc1.create('operation' => Action::MEMO_OPERATION, 'comments' => 'later')
      expect(action.processed_by).to eq(Insights::API::Common::Request.current.user.username)
    end
  end

  context 'invalid operations' do
    it 'forbids operation not prefined' do
      expect { svc1.create('operation' => 'strange operation', 'processed_by' => 'man') }.to raise_error(Exceptions::UserError)
    end

    context "when the child is in a notified state" do
      before do
        child1.update(:state => Request::NOTIFIED_STATE)
      end
    
      shared_examples_for "forbidden_operation" do |operation|
        it "forbids #{operation}" do
          expect { svc1.create('operation' => operation, 'processed_by' => 'man') }.to raise_error(Exceptions::InvalidStateTransitionError)
        end
      end
    
      [Action::START_OPERATION, Action::SKIP_OPERATION, Action::NOTIFY_OPERATION].each do |operation|
        it_behaves_like "forbidden_operation", operation
      end
    end

    it 'forbids approve operation from pending state' do
      expect { svc1.create('operation' => Action::APPROVE_OPERATION, 'processed_by' => 'man') }.to raise_error(Exceptions::InvalidStateTransitionError)
    end

    it 'forbids approve operation from already finished state' do
      child1.update(:state => Request::COMPLETED_STATE)
      expect { svc1.create('operation' => Action::APPROVE_OPERATION, 'processed_by' => 'man') }.to raise_error(Exceptions::InvalidStateTransitionError)
    end

    it 'forbids approve operation from already skipped state' do
      child1.update(:state => Request::SKIPPED_STATE)
      expect { svc1.create('operation' => Action::APPROVE_OPERATION, 'processed_by' => 'man') }.to raise_error(Exceptions::InvalidStateTransitionError)
    end

    it 'allows memo operation from any state' do
      child1.update(:state => Request::COMPLETED_STATE)
      expect { svc1.create('operation' => Action::MEMO_OPERATION, 'processed_by' => 'man', 'comments' => 'text') }.not_to raise_error
    end
  end
end
