RSpec.describe WorkflowLinkService do
  around do |example|
    ManageIQ::API::Common::Request.with_request(default_request_hash) { example.call }
  end

  let(:workflow) { create(:workflow, :with_tenant, :group_refs => [990]) }
  let(:object_id) { '123' }
  let(:obj_a) { {:object_type => 'inventory', :app_name => 'topology', :object_id => object_id} }
  let(:remote_tag_svc) { instance_double(RemoteTaggingService) }
  let(:tag) do
    { :namespace => WorkflowLinkService::TAG_NAMESPACE,
      :name      => WorkflowLinkService::TAG_NAME,
      :value     => workflow.id.to_s }
  end

  subject { described_class.new(workflow.id) }

  describe 'link' do
    before do
      allow(RemoteTaggingService).to receive(:new).with(obj_a).and_return(remote_tag_svc)
      allow(remote_tag_svc).to receive(:process).with('add', tag).and_return(remote_tag_svc)
    end

    it 'adds a new link' do
      subject.link(obj_a)
      expect(TagLink.count).to eq(1)
      expect(TagLink.first).to have_attributes(obj_a.merge(:workflow_id => workflow.id).except(:object_id))
    end

    it 'adds an existing link' do
      ActsAsTenant.with_tenant(workflow.tenant) do
        subject.link(obj_a)
        subject.link(obj_a)
        expect(TagLink.count).to eq(1)
      end
    end
  end
end
