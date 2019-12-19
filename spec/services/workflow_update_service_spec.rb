RSpec.describe WorkflowUpdateService do
  let(:workflow) { create(:workflow, :group_refs => [990, 991]) }

  subject { described_class.new(workflow.id) }

  context 'when update' do
    it 'with group_refs' do
      Insights::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) do
        subject.update(:group_refs => [999])
        workflow.reload
        expect(workflow.group_refs).to eq([999])
        expect(workflow.access_control_entries.size).to eq(1)
      end
    end
  end
end
