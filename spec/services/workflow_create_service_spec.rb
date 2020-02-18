RSpec.describe WorkflowCreateService do
  let(:template) { create(:template) }
  let(:group_refs) { %w[991 992 993] }
  let(:group) { instance_double(Group, :name => 'gname', :has_role? => true) }

  subject { described_class.new(template.id) }

  describe '#create' do
    before { allow(Group).to receive(:find).and_return(group) }

    it 'creates a request when group ids are valid' do
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

    it 'raises an error when the group has no approver role' do
      allow(group).to receive(:has_role?).and_return(false)
      Insights::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) do
        expect { subject.create(:name => 'workflow_1', :group_refs => group_refs) }.to raise_error(Exceptions::UserError, /does not have approver role/)
      end
    end
  end
end
