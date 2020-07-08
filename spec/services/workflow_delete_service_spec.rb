RSpec.describe WorkflowDeleteService do
  let(:workflows) { create_list(:workflow, 5) }
  let(:event_service) { double('event_service') }

  it 'deletes multiple sequences' do
    Thread.abort_on_exception = true
    trs = workflows.collect do |wf|
      Thread.new do
        allow(EventService).to receive(:new).and_return(event_service)

        expect(event_service).to receive(:workflow_deleted)
        described_class.new(wf.id).destroy
      end
    end
    trs.each { |t| t.join }
    expect(Workflow.count).to be_zero
  end
end
