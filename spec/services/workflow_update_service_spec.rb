RSpec.describe WorkflowUpdateService do
  let(:workflow) { create(:workflow, :group_refs => [990, 991]) }
  let(:aps) { instance_double(AccessProcessService) }

  subject { described_class.new(workflow.id) }

  context 'when update' do
    before do
      allow(AccessProcessService).to receive(:new).and_return(aps)
      allow(aps).to receive(:add_resource_to_groups)
      allow(aps).to receive(:remove_resource_from_groups)
    end

    it 'with group_refs' do
      subject.update(:group_refs => [999])
      workflow.reload
      expect(workflow.group_refs).to eq([999])
    end
  end
end
