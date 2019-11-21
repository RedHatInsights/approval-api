RSpec.xdescribe JbpmProcessService do
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
  subject { described_class.new(request) }

  let(:jbpm) { double(:jbpm, :api_client => double(:default_headers => {})) }

  before do
    allow(KieClient::ProcessInstancesBPMApi).to receive(:new).and_return(jbpm)
  end

  it 'starts a business process' do
    expect(jbpm).to receive(:start_process).with('approval', 'MultiStageEmails', hash_including(:body))
    subject.start
  end

  it 'sends a signal to a business process' do
    request.update_attributes(:process_ref => '100')
    expect(jbpm).to receive(:signal_process_instance).with('approval', '100', 'nextGroup', hash_including(:body))
    subject.signal('approved')
  end
end
