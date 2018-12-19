RSpec.describe WorkflowCreateService do
  let(:template) { create(:template) }
  let(:groups)   { create_list(:group, 3) }
  subject { described_class.new(template.id) }

  context 'create workflow' do
    it 'create a workflow with valid group ids' do
      workflow = subject.create(:name => 'workflow_1', :description => 'workflow with valid groups', :group_ids => groups.map(&:id), :template_id => template.id)
      workflow.reload

      expect(workflow.name).to eq('workflow_1')
      expect(workflow.description).to eq('workflow with valid groups')
      expect(workflow.template_id).to eq(template.id)
      expect(workflow.groups.map(&:id)).to eq(groups.map(&:id))
    end
  end
end
