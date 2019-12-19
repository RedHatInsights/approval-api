RSpec.describe WorkflowCreateService do
  let(:template) { create(:template) }
  let(:group_refs) { %w[991 992 993] }

  subject { described_class.new(template.id) }

  context 'create workflow' do
    it 'create a workflow with valid group ids' do
      Insights::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) do
        workflow = subject.create(:name => 'workflow_1', :description => 'workflow with valid groups', :group_refs => group_refs, :template_id => template.id)

        workflow.reload

        expect(workflow.name).to eq('workflow_1')
        expect(workflow.description).to eq('workflow with valid groups')
        expect(workflow.template_id).to eq(template.id)
        expect(workflow.group_refs).to eq(group_refs)
        expect(workflow.access_control_entries.size).to eq(3)
      end
    end
  end
end
