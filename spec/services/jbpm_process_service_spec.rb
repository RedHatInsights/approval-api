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

  let(:group) { double(:group, :uuid => 990) }
  let(:acs) { double(:ActionCreateService) }
  let(:workflow) { create(:workflow, :template => template) }
  let(:request)  { create(:request, :with_context, :with_tenant, :workflow => workflow) }
  subject { described_class.new(request) }

  let(:jbpm) { double(:jbpm, :api_client => double(:default_headers => {})) }

  before do
    allow(Group).to receive(:find).and_return(group)
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

  it '#valid_request? when workflow has empty groups' do
    allow(ActionCreateService).to receive(:new).and_return(acs)
    allow(acs).to receive(:create)

    expect(subject.valid_request?).to be_falsey
  end

  context '#valid_request?' do
    let(:workflow) { create(:workflow, :template => template, :group_refs => [group.uuid]) }

    it 'when workflow has groups' do
      allow(ActionCreateService).to receive(:new).and_return(acs)
      allow(acs).to receive(:create)
      allow(group).to receive(:users).and_return(['user'])
      allow(group).to receive(:exists?).and_return(true)
      allow(group).to receive(:has_role?).and_return(true)

      expect(subject.valid_request?).to be_truthy
    end
  end
end
