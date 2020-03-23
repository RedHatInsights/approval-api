RSpec.describe WorkflowUpdateService do
  let(:workflow) { create(:workflow, :group_refs => [{'name' => 'n990', 'uuid' => '990'}, {'name' => 'n991', 'uuid' => '991'}]) }

  subject { described_class.new(workflow.id) }

  context 'when update' do
    it 'with group_refs' do
      Insights::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) do
        expect(subject).to receive(:ensure_group).and_return(instance_double(Group, :name => 'newname', :has_role? => true))
        subject.update(:group_refs => [{'name' => 'n999', 'uuid' => '999'}])
        workflow.reload
        expect(workflow.group_refs.first).to include('name' => 'newname', 'uuid' => '999')
      end
    end
  end
end
