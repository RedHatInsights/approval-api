RSpec.describe JbpmProcessService do
  let(:common_setting) do
    {'processor_type' => 'jbpm', 'host' => 'http://url', 'username' => 'u', 'password' => 'p', 'container_id' => 'can'}
  end

  let(:template) do
    create(
      :template,
      :process_setting => common_setting.merge('process_id' => 'proc'),
      :signal_setting  => common_setting.merge('signal_name'  => 'sig'),
    )
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
