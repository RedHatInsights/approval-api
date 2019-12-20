RSpec.describe RequestCreateService do
  let(:template) { create(:template) }
  let(:workflow1) { create(:workflow, :group_refs => ['ref1'], :template => template) }
  let(:workflow2) { create(:workflow, :group_refs => ['ref2', 'ref3'], :template => template) }
  let(:resolved_workflows) { [] }

  before do
    allow(Group).to receive(:find).and_return(double(:group, :name => 'gname'))
    allow(WorkflowFindService).to receive(:new).and_return(double(:wfs, :find_by_tag_resources => resolved_workflows))
  end

  around do |example|
    Insights::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) do
      example.call
    end
  end

  context 'with auto fill requester' do
    it 'auto fills requester_name' do
      request = subject.create(:name => 'req1', :content => 'test me', :tag_resources => [])
      request.reload
      expect(request.requester_name).to include(Insights::API::Common::Request.current.user.last_name)
      expect(request.requester_name).to include(Insights::API::Common::Request.current.user.first_name)
    end
  end

  context 'without auto approval' do
    xcontext 'template has external process' do
      let(:template) { create(:template, :process_setting => {'processor_type' => 'jbpm', 'url' => 'url'}) }
      let(:resolved_workflows) { [workflow2] }

      it 'creates a request and immediately starts' do
        expect(JbpmProcessService).to receive(:new).and_return(double(:jbpm, :start => 100))
        request = subject.create(:name => 'req1', :content => 'test me')
        request.reload
        expect(request).to have_attributes(
          :name           => 'req1',
          :content        => 'test me',
          :requester_name => 'John Doe',
          :process_ref    => '100',
          :state          => Request::NOTIFIED_STATE,
          :decision       => Request::UNDECIDED_STATUS,
          :workflow       => nil
        )
        [0, 1].each do |index|
          stage = request.stages[index]
          expect(stage).to have_attributes(
            :state             => Stage::PENDING_STATE,
            :decision          => Stage::UNDECIDED_STATUS,
            :reason            => nil,
            :random_access_key => be_kind_of(String),
            :workflow          => workflow2
          )
        end
      end
    end

    context 'template has no external process' do
      let(:resolved_workflows) { [workflow1] }

      it 'creates a request in notified state' do
        request = subject.create(:name => 'req1', :content => 'test me')
        request.reload
        expect(request).to have_attributes(
          :name              => 'req1',
          :content           => 'test me',
          :requester_name    => 'John Doe',
          :owner             => 'jdoe',
          :state             => Request::NOTIFIED_STATE,
          :decision          => Request::UNDECIDED_STATUS,
          :random_access_key => be_kind_of(String)
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

    context 'with one workflow and one group' do
      let(:resolved_workflows) { [workflow1] }

      it 'creates one single request' do
        request = subject.create(:name => 'req1', :content => 'test me')
        request.reload
        expect(request).to have_attributes(
          :name           => 'req1',
          :content        => 'test me',
          :requester_name => 'John Doe',
          :owner          => 'jdoe',
          :state          => Request::COMPLETED_STATE,
          :decision       => Request::APPROVED_STATUS,
          :reason         => 'System approved',

          :number_of_children          => 0,
          :number_of_finished_children => 0
        )
      end
    end

    context 'with two workflows and three groups' do
      let(:resolved_workflows) { [workflow1, workflow2] }

      it 'creates a request with 3 children and auto approves all' do
        request = subject.create(:name => 'req1', :content => 'test me')
        request.reload
        expect(request).to have_attributes(
          :name           => 'req1',
          :content        => 'test me',
          :requester_name => 'John Doe',
          :owner          => 'jdoe',
          :state          => Request::COMPLETED_STATE,
          :decision       => Request::APPROVED_STATUS,
          :reason         => 'System approved',

          :number_of_children          => 3,
          :number_of_finished_children => 3,
          :random_access_key           => nil
        )
        (0..2).each do |index|
          child = request.children[index]
          expect(child).to have_attributes(
            :state             => Request::COMPLETED_STATE,
            :decision          => Request::APPROVED_STATUS,
            :reason            => 'System approved',
            :random_access_key => nil
          )
          expect(child.actions.first).to have_attributes(
            :operation    => Action::START_OPERATION,
            :processed_by => 'system',
          )
          expect(child.actions.second).to have_attributes(
            :operation    => Action::NOTIFY_OPERATION,
            :processed_by => 'system',
          )
          expect(child.actions.last).to have_attributes(
            :operation => Action::APPROVE_OPERATION,
            :comments  => 'System approved'
          )
        end
      end
    end
  end

  context 'request has no matched tag links' do
    let(:context_service) { double(:conext_service) }
    let(:tag_resources) do
      [{
        'app_name'    => 'app1',
        'object_type' => 'otype1',
        'tags'        => [{:tag => '/ns1/name1=v1'}]
      }]
    end
    let(:workflow) { create(:workflow) }

    before do
      allow(Thread).to receive(:new).and_yield
      allow(Workflow).to receive(:default_workflow).and_return(workflow)
    end

    it 'creates a request and auto approves' do
      expect(ContextService).to receive(:new).and_return(context_service)
      expect(context_service).to receive(:with_context).and_yield

      request = subject.create(:name => 'req2', :content => 'test me', :tag_resources => tag_resources)
      request.reload
      expect(request).to have_attributes(
        :name           => 'req2',
        :content        => 'test me',
        :requester_name => 'John Doe',
        :owner          => 'jdoe',
        :state          => Request::COMPLETED_STATE,
        :decision       => Request::APPROVED_STATUS,
        :reason         => 'System approved',
        :workflow       => workflow
      )
    end
  end
end
