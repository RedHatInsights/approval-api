RSpec.describe WorkflowFindService do
  let(:workflow) { create(:workflow, :with_tenant, :group_refs => [990]) }
  let(:obj_a) { {:object_type => 'inventory', :app_name => 'topology', :object_id => 'abc'} }

  describe 'find' do
    before { WorkflowLinkService.new(workflow.id).link(obj_a) }

    it 'finds workflow ids based on tags' do
      another_tag = obj_a.merge(:app_name => 'catalog')
      expect(subject.find([another_tag, obj_a])).to eq([nil, workflow.id])
    end
  end
end
