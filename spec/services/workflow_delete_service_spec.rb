RSpec.describe WorkflowDeleteService do
  let(:workflows) { create_list(:workflow, 5) }

  it 'deletes multiple sequences' do
    Thread.abort_on_exception = true
    trs = workflows.collect do |wf|
      Thread.new do
        described_class.new(wf.id).destroy
      end
    end
    trs.each { |t| t.join }
    expect(Workflow.count).to be_zero
  end
end
