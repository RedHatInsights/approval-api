RSpec.describe WorkflowCreateService do
  let(:template) { create(:template) }
  let(:group_refs) { %w[991 992 993] }
  let(:aps) { instance_double(AccessProcessService) }

  subject { described_class.new(template.id) }

  context 'create workflow' do
    before do
      allow(AccessProcessService).to receive(:new).and_return(aps)
      allow(aps).to receive(:add_resource_to_groups)
    end
    it 'create a workflow with valid group ids' do
      Insights::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) do
        workflow = subject.create(:name => 'workflow_1', :description => 'workflow with valid groups', :group_refs => group_refs, :template_id => template.id)

        workflow.reload

        expect(workflow.name).to eq('workflow_1')
        expect(workflow.description).to eq('workflow with valid groups')
        expect(workflow.template_id).to eq(template.id)
        expect(workflow.group_refs).to eq(group_refs)
      end
    end
  end
end
