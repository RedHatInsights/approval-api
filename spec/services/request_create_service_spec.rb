RSpec.describe RequestCreateService do
  let(:template) { create(:template) }
  let(:workflow1) { create(:workflow, :group_refs => [{'uuid' => 'ref1'}], :template => template) }
  let(:workflow2) { create(:workflow, :group_refs => [{'uuid' => 'ref2'}, {'uuid' => 'ref3'}], :template => template) }
  let(:resolved_workflows) { [] }
  let(:group) { instance_double(Group, :name => 'gname', :has_role? => true, :users => ['user']) }

  before do
    allow(Thread).to receive(:new).and_yield
    allow(Group).to receive(:find).and_return(group)
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
    context 'template has external process' do
      let(:template) { create(:template, :process_setting => {'processor_type' => 'jbpm', 'url' => 'url'}) }
      let(:resolved_workflows) { [workflow2] }

      it 'creates a request and immediately starts' do
        expect(JbpmProcessService).to receive(:new).twice.and_return(double(:jbpm, :start => 100))
        request = subject.create(:name => 'req1', :content => 'test me')
        request.reload
        expect(request).to have_attributes(
          :name                        => 'req1',
          :content                     => 'test me',
          :requester_name              => 'John Doe',
          :process_ref                 => nil,
          :state                       => Request::STARTED_STATE,
          :decision                    => Request::UNDECIDED_STATUS,
          :workflow                    => nil,
          :group_ref                   => nil,
          :group_name                  => 'gname,gname',
          :number_of_children          => 2,
          :number_of_finished_children => 0
        )
        [0, 1].each do |index|
          subrequest = request.requests[index]
          expect(subrequest).to have_attributes(
            :process_ref => '100',
            :state       => Request::STARTED_STATE,
            :decision    => Request::UNDECIDED_STATUS,
            :reason      => nil,
            :workflow    => workflow2,
            :group_name  => 'gname'
          )
          expect(request.requests.first.group_ref).to eq('ref3');
          expect(request.requests.second.group_ref).to eq('ref2');
        end
      end

      it 'creates a request with invalid group' do
        allow(group).to receive(:has_role?).and_return(false)

        expect { subject.create(:name => 'req1', :content => 'test me') }.to raise_error(Exceptions::UserError, /does not have approver role/)
      end
    end

    context 'template has no external process' do
      let(:resolved_workflows) { [workflow1] }

      it 'creates a request in notified state' do
        request = subject.create(:name => 'req1', :content => 'test me')
        request.reload
        expect(request).to have_attributes(
          :name                        => 'req1',
          :content                     => 'test me',
          :requester_name              => 'John Doe',
          :owner                       => 'jdoe',
          :state                       => Request::NOTIFIED_STATE,
          :decision                    => Request::UNDECIDED_STATUS,
          :group_ref                   => 'ref1',
          :group_name                  => 'gname',
          :number_of_children          => 0,
          :number_of_finished_children => 0
        )
      end
    end
  end

  context 'auto approval instructed by an environment variable' do
    let(:envs) do
      {
        :AUTO_APPROVAL          => 'y',
        :AUTO_APPROVAL_INTERVAL => '0.1'
      }
    end

    context 'with one workflow and one group' do
      let(:resolved_workflows) { [workflow1] }

      it 'creates one single request' do
        RequestSpecHelper.with_modified_env(envs) do
          request = subject.create(:name => 'req1', :content => 'test me')
          request.reload
          expect(request).to have_attributes(
            :name                        => 'req1',
            :content                     => 'test me',
            :requester_name              => 'John Doe',
            :owner                       => 'jdoe',
            :state                       => Request::COMPLETED_STATE,
            :decision                    => Request::APPROVED_STATUS,
            :reason                      => described_class::AUTO_APPROVED_REASON,
            :group_ref                   => 'ref1',
            :group_name                  => 'gname',
            :number_of_children          => 0,
            :number_of_finished_children => 0
          )
        end
      end
    end

    context 'with two workflows and three groups' do
      let(:resolved_workflows) { [workflow1, workflow2] }

      it 'creates a request with 3 children and auto approves all' do
        RequestSpecHelper.with_modified_env(envs) do
          request = subject.create(:name => 'req1', :content => 'test me')
          request.reload
          expect(request).to have_attributes(
            :name                        => 'req1',
            :content                     => 'test me',
            :requester_name              => 'John Doe',
            :owner                       => 'jdoe',
            :state                       => Request::COMPLETED_STATE,
            :decision                    => Request::APPROVED_STATUS,
            :reason                      => described_class::AUTO_APPROVED_REASON,
            :group_ref                   => nil,
            :group_name                  => 'gname,gname,gname',
            :number_of_children          => 3,
            :number_of_finished_children => 3
          )
          (0..2).each do |index|
            child = request.requests[index]
            expect(child).to have_attributes(
              :state      => Request::COMPLETED_STATE,
              :decision   => Request::APPROVED_STATUS,
              :reason     => described_class::AUTO_APPROVED_REASON,
              :group_name => 'gname'
            )
            expect(child.actions.first).to have_attributes(
              :operation    => Action::START_OPERATION,
              :processed_by => 'system'
            )
            expect(child.actions.second).to have_attributes(
              :operation    => Action::NOTIFY_OPERATION,
              :processed_by => 'system'
            )
            expect(child.actions.last).to have_attributes(
              :operation => Action::APPROVE_OPERATION,
              :comments  => described_class::AUTO_APPROVED_REASON
            )
          end
          expect(request.requests.first.group_ref).to eq('ref3');
          expect(request.requests.second.group_ref).to eq('ref2');
          expect(request.requests.last.group_ref).to eq('ref1');
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
        :reason         => described_class::AUTO_APPROVED_REASON,
        :workflow       => nil,
        :group_name     => described_class::SYSTEM_APPROVAL
      )
    end
  end
end
