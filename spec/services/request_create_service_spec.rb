RSpec.describe RequestCreateService do
  let(:template) { create(:template) }
  let(:group_refs) { ["991"] }
  let(:workflow) { create(:workflow, :group_refs => group_refs, :template => template) }
  subject { described_class.new(workflow.id) }

  before { allow(Group).to receive(:find) }

  context 'without auto approval' do
    context 'template has external process' do
      let(:template) { create(:template, :process_setting => {'url' => 'url'}) }

      it 'creates a request in pending state' do
        request = subject.create(:name => 'req1', :requester => 'test', :content => 'test me')
        request.reload
        expect(request).to have_attributes(
          :name      => 'req1',
          :requester => 'test',
          :content   => 'test me',
          :state     => Request::PENDING_STATE,
          :decision  => Request::UNDECIDED_STATUS
        )
      end
    end

    context 'template has no external process' do
      it 'creates a request in notified state' do
        request = subject.create(:name => 'req1', :requester => 'test', :content => 'test me')
        request.reload
        expect(request).to have_attributes(
          :name      => 'req1',
          :requester => 'test',
          :content   => 'test me',
          :state     => Request::NOTIFIED_STATE,
          :decision  => Request::UNDECIDED_STATUS
        )
      end
    end
  end

  context 'auto approval instructed by an environment variable' do
    before do
      allow(Thread).to receive(:new).and_yield
      ENV['AUTO_APPROVAL'] = 'y'
      ENV['AUTO_APPROVAL_INTERVAL'] = '0.1'
    end

    after do
      ENV['AUTO_APPROVAL'] = nil
      ENV['AUTO_APPROVAL_INTERVAL'] = nil
    end

    it 'creates a request and auto approves' do
      request = subject.create(:name => 'req1', :requester => 'test', :content => 'test me')
      request.reload
      expect(request).to have_attributes(
        :name      => 'req1',
        :requester => 'test',
        :content   => 'test me',
        :state     => Request::FINISHED_STATE,
        :decision  => Request::APPROVED_STATUS,
        :reason    => 'ok'
      )
      expect(request.stages.first).to have_attributes(
        :state    => Stage::FINISHED_STATE,
        :decision => Stage::APPROVED_STATUS,
        :reason   => 'ok'
      )
      expect(request.stages.first.actions.first).to have_attributes(
        :operation    => Action::NOTIFY_OPERATION,
        :processed_by => 'system',
      )
      expect(request.stages.first.actions.last).to have_attributes(
        :operation => Action::APPROVE_OPERATION,
        :comments  => 'ok'
      )
    end
  end

  context 'auto approval with a seeded workflow' do
    let(:workflow) do
      Workflow.seed
      Workflow.first
    end

    before { allow(Thread).to receive(:new).and_yield }

    it 'creates a request and auto approves' do
      request = subject.create(:name => 'req2', :requester => 'test2', :content => 'test me')
      request.reload
      expect(request).to have_attributes(
        :name      => 'req2',
        :requester => 'test2',
        :content   => 'test me',
        :state     => Request::FINISHED_STATE,
        :decision  => Request::APPROVED_STATUS,
        :reason    => 'System approved'
      )
    end
  end
end
