RSpec.describe WorkflowLinkService do
  let(:workflow) { create(:workflow, :with_tenant, :group_refs => [990]) }
  let(:obj_a) { {:object_type => 'inventory', :app_name => 'topology', :object_id => 'abc'} }

  subject { described_class.new(workflow.id) }

  describe 'link' do
    it 'adds a new link' do
      subject.link(obj_a)
      expect(TagLink.count).to eq(1)
      expect(TagLink.first).to have_attributes(obj_a.merge(:workflow_id => workflow.id))
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
