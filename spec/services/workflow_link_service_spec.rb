RSpec.describe WorkflowLinkService do
  let(:workflow) { create(:workflow, :with_tenant, :group_refs => [990]) }
  let(:a_tag) { {:object_type => 'inventory', :app_name => 'topology', :tag_name => '/approval/workflows/abc'} }

  subject { described_class.new(workflow.id) }

  describe 'link' do
    it 'adds a new link' do
      subject.link(a_tag)
      expect(TagLink.count).to eq(1)
      expect(TagLink.first).to have_attributes(a_tag.merge(:workflow_id => workflow.id))
    end

    it 'adds an existing link' do
      ActsAsTenant.with_tenant(workflow.tenant) do
        subject.link(a_tag)
        subject.link(a_tag)
        expect(TagLink.count).to eq(1)
      end
    end
  end
end
