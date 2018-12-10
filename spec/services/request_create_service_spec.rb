RSpec.describe RequestCreateService do
  let(:workflow) { create(:workflow, :groups => [create(:group)]) }
  subject { described_class.new(workflow.id) }

  context 'without auto approval' do
    it 'creates a request' do
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

  describe '#create' do
    before do
      allow(Thread).to receive(:new).and_yield
      ENV['AUTO_APPROVAL'] = 'y'
      ENV['AUTO_APPROVAL_INTERVAL'] = '0.1'
    end

    after do
      ENV['AUTO_APPROVAL'] = 'y'
      ENV['AUTO_APPROVAL_INTERVAL'] = '0.1'
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
end
