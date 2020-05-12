RSpec.describe WorkflowCreateService do
  around do |example|
    Insights::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) { example.call }
  end

  let(:template) { create(:template) }
  let(:group_refs) { [{'name' => 'n991', 'uuid' => '991'}, {'name' => 'n992', 'uuid' => '992'}, {'name' => 'n993', 'uuid' => '993'}] }
  let(:group) { instance_double(Group, :name => 'gname', :can_approve? => true) }

  subject { described_class.new(template.id) }

  describe '#create' do
    before { allow(Group).to receive(:find).and_return(group) }

    context 'when group_refs are valid' do
      it 'creates a request' do
        workflow = subject.create(:name => 'workflow_1', :description => 'workflow with valid groups', :group_refs => group_refs, :template_id => template.id)

        workflow.reload

        expect(workflow.name).to eq('workflow_1')
        expect(workflow.description).to eq('workflow with valid groups')
        expect(workflow.template_id).to eq(template.id)
        expect(workflow.group_refs.size).to eq(3)
      end
    end

    context 'when group_refs contains duplicates' do
      let(:group_refs) { [{'name' => 'n991', 'uuid' => '991'}, {'name' => 'n992', 'uuid' => '992'}, {'name' => 'n993', 'uuid' => '992'}] }

      it 'raises an user' do
        expect { subject.create(:name => 'workflow_1', :group_refs => group_refs) }.to raise_error(Exceptions::UserError, /Duplicated group UUID was detected/)
      end
    end

    context 'when the group has no approver role' do
      it 'raises an error' do
        allow(group).to receive(:can_approve?).and_return(false)
        expect { subject.create(:name => 'workflow_1', :group_refs => group_refs) }.to raise_error(Exceptions::UserError, /does not have approver role/)
      end
    end
  end
end
