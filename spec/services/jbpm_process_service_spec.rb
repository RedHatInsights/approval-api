RSpec.describe JbpmProcessService, :type => :request do
  let(:test_env) do
    {
      :APPROVAL_PAM_SERVICE_HOST => 'localhost',
      :APPROVAL_PAM_SERVICE_PORT => '8080',
      :KIE_SERVER_USERNAME       => 'executionUser',
      :KIE_SERVER_PASSWORD       => 'password'
    }
  end

  let(:template) do
    with_modified_env(test_env) do
      Template.seed
      Template.find_by(:title => 'Basic')
    end
  end

  let(:workflow) { create(:workflow, :template => template) }
  let(:request)  { create(:request, :with_context, :workflow => workflow) }
  subject { described_class.new(request) }

  let(:jbpm) { double(:jbpm, :api_client => double(:default_headers => {})) }

  before do
    allow(Group).to receive(:find)
    allow(KieClient::ProcessInstancesBPMApi).to receive(:new).and_return(jbpm)
  end

  it 'starts a business process' do
    expect(subject).to receive(:enhance_groups)
    expect(jbpm).to receive(:start_process).with('approval', 'MultiStageEmails', hash_including(:body))
    subject.start
  end

  it 'sends a signal to a business process' do
    request.update_attributes(:process_ref => '100')
    expect(jbpm).to receive(:signal_process_instance).with('approval', '100', 'nextGroup', hash_including(:body))
    subject.signal('approved')
  end

  describe '#enhance_groups' do
    let(:orig_groups) do
      [{"uuid"        => "177a97e2",
        "name"        => "Group 1",
        "description" => "Group 1",
        "roles"       => [],
        "users"       =>
                         [{"username"   => "jsmith",
                           "email"      => "a@b.com",
                           "first_name" => "Joe",
                           "last_name"  => "Smith"}]}]
    end

    it 'inserts random_access_key to user' do
      allow(SecureRandom).to receive(:hex).and_return('random-access')

      mod_groups = subject.send(:enhance_groups, orig_groups)
      expect(mod_groups.first['users'].first['random_access_key']).to eq('random-access')

      request.reload
      expect(request.random_access_keys.first).to have_attributes(:access_key => 'random-access', :approver_name => 'Joe Smith')
    end
  end

  describe 'kie service raise exception' do
    shared_examples_for "expect_failure" do |exception, op, *op_args|
      it 'posts an error action' do
        allow(jbpm).to receive(op).and_raise(exception)
        allow(subject).to receive(:enhance_groups)
        expect { subject.send(*op_args) }.to raise_exception(Exception)

        request.reload

        expect(request.state).to eq(Request::FAILED_STATE)
        expect(request.decision).to eq(Request::ERROR_STATUS)
        expect(request.reason).to eq(exception.message)
      end
    end

    describe '#start' do
      it_behaves_like 'expect_failure', Exceptions::KieError.new("kie error"), :start_process, :start
      it_behaves_like 'expect_failure', Exceptions::NetworkError.new("network error"), :start_process, :start
    end

    describe '#signal' do
      it_behaves_like 'expect_failure', Exceptions::KieError.new("kie error"), :signal_process_instance, :signal, 'approved'
      it_behaves_like 'expect_failure', Exceptions::NetworkError.new("network error"), :signal_process_instance, :signal, 'approved'
    end
  end
end
