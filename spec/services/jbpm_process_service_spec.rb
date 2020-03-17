RSpec.describe JbpmProcessService do
  let(:template) do
    ENV['APPROVAL_PAM_SERVICE_HOST'] = 'localhost'
    ENV['APPROVAL_PAM_SERVICE_PORT'] = '8080'
    ENV['KIE_SERVER_USERNAME']       = 'executionUser'
    ENV['KIE_SERVER_PASSWORD']       = 'password'

    Template.seed

    ENV['APPROVAL_PAM_SERVICE_HOST'] = nil
    ENV['APPROVAL_PAM_SERVICE_PORT'] = nil
    ENV['KIE_SERVER_USERNAME']       = nil
    ENV['KIE_SERVER_PASSWORD']       = nil

    Template.find_by(:title => 'Basic')
  end

  let(:workflow) { create(:workflow, :template => template) }
  let(:request)  { create(:request, :with_context, :workflow => workflow) }
  let(:kie_ex)   { Exceptions::KieError.new("kie error") }
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
            "last_name"  => "Smith"}]
      }]
    end

    it 'inserts random_access_key to user' do
      allow(SecureRandom).to receive(:hex).and_return('random-access')

      mod_groups = subject.send(:enhance_groups, orig_groups)
      expect(mod_groups.first['users'].first['random_access_key']).to eq('random-access')

      request.reload
      expect(request.random_access_keys.first).to have_attributes(:access_key => 'random-access', :approver_name => 'Joe Smith')
    end
  end

  context 'when kie service raise exception' do
    before do
      allow(jbpm).to receive(:start_process).and_raise(kie_ex)
      allow(subject).to receive(:enhance_groups)
    end

    it 'should post an error action' do
      expect { subject.start }.to raise_exception(Exceptions::KieError)

      request.reload

      expect(request.state).to eq(Request::FAILED_STATE)
      expect(request.decision).to eq(Request::ERROR_STATUS)
      expect(request.reason).to eq(kie_ex.message)
    end
  end
end
