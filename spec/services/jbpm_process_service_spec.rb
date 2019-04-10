RSpec.describe JbpmProcessService do
  let(:template) do
    ENV['APPROVAL_PAM_SERVICE_HOST'] = 'localhost'
    ENV['APPROVAL_PAM_SERVICE_PORT'] = '8080'
    ENV['KIE_SERVER_USERNAME']       = 'executionUser'
    ENV['KIE_SERVER_PASSWORD']       = 'password'
    ENV['KIE_CONTAINER_ID']          = 'can'
    ENV['BPM_BML_PROCESS_ID']        = 'proc'
    ENV['BPM_BML_SIGNAL_NAME']       = 'sig'

    Template.seed

    ENV['APPROVAL_PAM_SERVICE_HOST'] = nil
    ENV['APPROVAL_PAM_SERVICE_PORT'] = nil
    ENV['KIE_SERVER_USERNAME']       = nil
    ENV['KIE_SERVER_PASSWORD']       = nil
    ENV['KIE_CONTAINER_ID']          = nil
    ENV['BPM_BML_PROCESS_ID']        = nil
    ENV['BPM_BML_SIGNAL_NAME']       = nil

    Template.find_by(:title => 'Basic')
  end

  let(:workflow) { create(:workflow, :template => template) }
  let(:request)  { create(:request, :workflow => workflow) }
  subject { described_class.new(request) }

  let(:jbpm) { double(:jbpm, :api_client => double(:default_headers => {})) }

  before do
    allow(KieClient::ProcessInstancesBPMApi).to receive(:new).and_return(jbpm)
  end

  it 'starts a business process' do
    expect(jbpm).to receive(:start_process).with('can', 'proc', hash_including(:body))
    subject.start
  end

  it 'sends a signal to a business process' do
    request.update_attributes(:process_ref => '100')
    expect(jbpm).to receive(:signal_process_instance).with('can', '100', 'sig', hash_including(:body))
    subject.signal('approved')
  end
end
