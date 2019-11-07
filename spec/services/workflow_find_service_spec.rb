RSpec.describe WorkflowFindService do
  let(:workflow) { create(:workflow, :with_tenant, :group_refs => [990]) }
  let(:obj) { {:object_type => 'inventory', :app_name => 'topology', :object_id => 'abc'} }
  let(:another_obj) { {:object_type => 'portfolio', :app_name => 'catalog', :object_id => 'abc'} }
  let(:add_tag_svc) { instance_double(AddRemoteTags) }
  let(:get_tag_svc) { instance_double(GetRemoteTags, :tags => [tag]) }
  let(:tag) do
    { :namespace => WorkflowLinkService::TAG_NAMESPACE,
      :name      => WorkflowLinkService::TAG_NAME,
      :value     => workflow.id.to_s }
  end

  describe 'find' do
    before do
      allow(AddRemoteTags).to receive(:new).with(obj).and_return(add_tag_svc)
      allow(add_tag_svc).to receive(:process).with(tag).and_return(add_tag_svc)
      allow(GetRemoteTags).to receive(:new).with(obj).and_return(get_tag_svc)
      allow(GetRemoteTags).to receive(:new).with(another_obj).and_return(get_tag_svc)
      allow(get_tag_svc).to receive(:process).and_return(get_tag_svc)
      WorkflowLinkService.new(workflow.id).link(obj)
    end

    it 'finds workflow based on tags' do
      workflows = subject.find(obj)
      expect(workflows.first.id).to eq(workflow.id)
    end

    it 'Cannot find workflow based on tags' do
      another_workflows = subject.find(another_obj)
      expect(another_workflows).to eq([])
    end
  end

  describe 'find_by_tag_resources' do
    include_context "tag_resource_objects"

    it 'finds sorted workflow based on tags' do
      workflows = subject.find_by_tag_resources([tag_resource1])
      expect(workflows).to eq([workflow2, workflow1])
    end

    it 'if tags is empty returns empty array' do
      workflows = subject.find_by_tag_resources([tagless_resource])
      expect(workflows).to be_empty
    end

    it 'if input is empty array return empty array' do
      workflows = subject.find_by_tag_resources([])
      expect(workflows).to be_empty
    end
  end
end
