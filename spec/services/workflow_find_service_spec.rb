RSpec.describe WorkflowFindService do
  let(:workflow) { create(:workflow, :with_tenant, :group_refs => [990]) }
  let(:obj) { {:object_type => 'inventory', :app_name => 'topology', :object_id => 'abc'} }
  let(:remote_tag_svc) { instance_double(RemoteTaggingService) }
  let(:tag) do
    { :namespace => WorkflowLinkService::TAG_NAMESPACE,
      :name      => WorkflowLinkService::TAG_NAME,
      :value     => workflow.id.to_s }
  end

  describe 'find' do
    before do
      allow(RemoteTaggingService).to receive(:new).with(obj).and_return(remote_tag_svc)
      allow(remote_tag_svc).to receive(:process).with('add', tag).and_return(remote_tag_svc)
      WorkflowLinkService.new(workflow.id).link(obj)
    end

    it 'finds workflow based on tags' do
      workflows = subject.find(obj)
      expect(workflows.first.id).to eq(workflow.id)
    end

    it 'Cannot find workflow based on tags' do
      another_obj = obj.merge(:app_name => 'catalog')
      another_workflows = subject.find(another_obj)
      expect(another_workflows).to eq([])
    end
  end
end
