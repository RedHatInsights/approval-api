RSpec.describe WorkflowLinkService, :type => :request do
  around do |example|
    Insights::API::Common::Request.with_request(default_request_hash) { example.call }
  end

  let(:group) { instance_double(Group, :name => 'gname', :uuid => 990, :has_role? => true) }
  let(:workflow) { create(:workflow, :with_tenant, :group_refs => [990]) }
  let(:obj_a) { {:object_type => 'inventory', :app_name => 'topology', :object_id => '123'} }
  let(:remote_tag_svc) { instance_double(AddRemoteTags) }
  let(:tag) do
    { 'tag' => "/#{WorkflowLinkService::TAG_NAMESPACE}/#{WorkflowLinkService::TAG_NAME}=#{workflow.id}" }
  end

  subject { described_class.new(workflow.id) }

  describe '#link' do
    before do
      allow(Group).to receive(:find).and_return(group)
      allow(AddRemoteTags).to receive(:new).with(obj_a).and_return(remote_tag_svc)
      allow(remote_tag_svc).to receive(:process).with([tag]).and_return(remote_tag_svc)
    end

    it 'adds a new link when group is valid' do
      subject.link(obj_a)
      expect(TagLink.count).to eq(1)
      expect(TagLink.first).to have_attributes(obj_a.merge(:workflow_id => workflow.id).except(:object_id))
    end

    it 'fails to add a new link when the group is invalid' do
      allow(group).to receive(:has_role?).and_return(false)
      expect { subject.link(obj_a) }.to raise_error(Exceptions::UserError, /does not have approver role/)
    end

    it 'adds the same link only once' do
      ActsAsTenant.with_tenant(workflow.tenant) do
        subject.link(obj_a)
        subject.link(obj_a)
        expect(TagLink.count).to eq(1)
      end
    end
  end
end
