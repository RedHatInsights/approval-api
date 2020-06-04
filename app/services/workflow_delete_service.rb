class WorkflowDeleteService
  attr_accessor :workflow_id

  def initialize(workflow_id)
    self.workflow_id = workflow_id
  end

  def destroy
    begin
      retries ||= 0
      Workflow.find(workflow_id).destroy!
    rescue ActiveRecord::RecordNotUnique, Exceptions::NegativeSequence # Failed to update sequence after deletion due to concurrent issue
      retry if (retries += 1) < 3
    end
  end

end
