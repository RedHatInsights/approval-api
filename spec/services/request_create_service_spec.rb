RSpec.describe RequestCreateService do
  let(:template) { create(:template) }
  let(:group_refs) { %w[991 992] }
  let(:workflow) { create(:workflow, :group_refs => group_refs, :template => template) }
  subject { described_class.new(workflow.id) }

  before { allow(Group).to receive(:find) }

  around do |example|
    ManageIQ::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) do
      example.call
    end
  end

  context 'with auto fill requester' do
    it 'auto fill requester if it is nil' do
      request = subject.create(:name => 'req1', :content => 'test me')
      request.reload
      expect(request.requester).to include(ManageIQ::API::Common::Request.current.user.last_name)
      expect(request.requester).to include(ManageIQ::API::Common::Request.current.user.first_name)
    end

    it 'skips auto filling if requester is set' do
      request = subject.create(:name => 'req1', :requester => 'test', :content => 'test me')
      request.reload
      expect(request.requester).to eq("test")
    end
  end

  context 'without auto approval' do
    context 'template has external process' do
      let(:template) { create(:template, :process_setting => {'processor_type' => 'jbpm', 'url' => 'url'}) }

      it 'creates a request and immediately starts' do
        expect(JbpmProcessService).to receive(:new).and_return(double(:jbpm, :start => 100))
        request = subject.create(:name => 'req1', :requester => 'test', :content => 'test me')
        request.reload
        expect(request).to have_attributes(
          :name        => 'req1',
          :requester   => 'test',
          :content     => 'test me',
          :process_ref => '100',
          :state       => Request::NOTIFIED_STATE,
          :decision    => Request::UNDECIDED_STATUS
        )
        [0, 1].each do |index|
          stage = request.stages[index]
          expect(stage).to have_attributes(
            :state             => Stage::PENDING_STATE,
            :decision          => Stage::UNDECIDED_STATUS,
            :reason            => nil,
            :random_access_key => be_kind_of(String)
          )
        end
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
      [0, 1].each do |index|
        stage = request.stages[index]
        expect(stage).to have_attributes(
          :state             => Stage::FINISHED_STATE,
          :decision          => Stage::APPROVED_STATUS,
          :reason            => 'ok',
          :random_access_key => nil
        )
        expect(stage.actions.first).to have_attributes(
          :operation    => Action::NOTIFY_OPERATION,
          :processed_by => 'system',
        )
        expect(stage.actions.last).to have_attributes(
          :operation => Action::APPROVE_OPERATION,
          :comments  => 'ok'
        )
      end
    end
  end

  context 'auto approval with a seeded workflow' do
    let(:workflow) do
      Workflow.seed
      Workflow.first
    end
    let(:context_service) { double(:conext_service) }

    before { allow(Thread).to receive(:new).and_yield }
    after  { Workflow.instance_variable_set(:@default_workflow, nil) }

    it 'creates a request and auto approves' do
      expect(ContextService).to receive(:new).and_return(context_service)
      expect(context_service).to receive(:with_context).and_yield

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
