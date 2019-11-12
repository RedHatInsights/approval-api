RSpec.describe RequestCreateService do
  let(:template) { create(:template) }

  before { allow(Group).to receive(:find) }

  around do |example|
    ManageIQ::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) do
      example.call
    end
  end

  context 'with auto fill requester' do
    it 'auto fills requester_name' do
      request = subject.create(:name => 'req1', :content => 'test me', :tag_resources => [])
      request.reload
      expect(request.requester_name).to include(ManageIQ::API::Common::Request.current.user.last_name)
      expect(request.requester_name).to include(ManageIQ::API::Common::Request.current.user.first_name)
    end
  end

  xcontext 'without auto approval' do
    context 'template has external process' do
      let(:template) { create(:template, :process_setting => {'processor_type' => 'jbpm', 'url' => 'url'}) }

      it 'creates a request and immediately starts' do
        expect(JbpmProcessService).to receive(:new).and_return(double(:jbpm, :start => 100))
        request = subject.create(:name => 'req1', :requester_name => 'test', :content => 'test me')
        request.reload
        expect(request).to have_attributes(
          :name           => 'req1',
          :content        => 'test me',
          :requester_name => 'test',
          :process_ref    => '100',
          :state          => Request::NOTIFIED_STATE,
          :decision       => Request::UNDECIDED_STATUS
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
        request = subject.create(:name => 'req1', :requester_name => 'test', :content => 'test me')
        request.reload
        expect(request).to have_attributes(
          :name           => 'req1',
          :content        => 'test me',
          :requester_name => 'test',
          :owner          => 'jdoe',
          :state          => Request::NOTIFIED_STATE,
          :decision       => Request::UNDECIDED_STATUS
        )
      end
    end
  end

  xcontext 'auto approval instructed by an environment variable' do
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
      request = subject.create(:name => 'req1', :requester_name => 'test', :content => 'test me')
      request.reload
      expect(request).to have_attributes(
        :name           => 'req1',
        :content        => 'test me',
        :requester_name => 'test',
        :owner          => 'jdoe',
        :state          => Request::FINISHED_STATE,
        :decision       => Request::APPROVED_STATUS,
        :reason         => 'ok'
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

  context 'request has no matched tag links' do
    let(:context_service) { double(:conext_service) }
    let(:tag_resources) do
      [{
        'app_name'    => 'app1',
        'object_type' => 'otype1',
        'tags'        => [{'namespace' => 'ns1', 'name' => 'name1', 'value' => 'v1'}]
      }]
    end

    before { allow(Thread).to receive(:new).and_yield }

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
        :state          => Request::FINISHED_STATE,
        :decision       => Request::APPROVED_STATUS,
        :reason         => 'System approved'
      )
    end
  end
end
