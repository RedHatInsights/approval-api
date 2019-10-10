RSpec.describe WorkflowFindService do
  let(:workflow) { create(:workflow, :with_tenant, :group_refs => [990]) }
  let(:a_tag) { {:object_type => 'inventory', :app_name => 'topology', :tag_name => '/approval/workflows/abc'} }

  describe 'find' do
    before { WorkflowLinkService.new(workflow.id).link(a_tag) }

    it 'finds workflow ids based on tags' do
      another_tag = a_tag.merge(:app_name => 'catalog')
      expect(subject.find([another_tag, a_tag])).to eq([nil, workflow.id])
    end
  end
end
