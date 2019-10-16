RSpec.describe WorkflowFindService do
  let(:workflow) { create(:workflow, :with_tenant, :group_refs => [990]) }
  let(:obj) { {:object_type => 'inventory', :app_name => 'topology', :object_id => 'abc'} }

  describe 'find' do
    before { WorkflowLinkService.new(workflow.id).link(obj) }

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
