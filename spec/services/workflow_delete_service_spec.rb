RSpec.describe WorkflowDeleteService do
  let(:workflow) { create(:workflow, :group_refs => [990, 991]) }
  let(:aps) { instance_double(AccessProcessService) }

  subject { described_class.new(workflow.id) }

  context 'when delete' do
    before do
      allow(AccessProcessService).to receive(:new).and_return(aps)
      allow(aps).to receive(:remove_resource_from_groups)
    end

    it 'returns nil after deletion' do
      Insights::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) do
        subject.delete

        expect(Workflow.find_by(:id => workflow.id)).to be_nil
      end
    end
  end
end
