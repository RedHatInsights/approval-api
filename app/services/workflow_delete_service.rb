class WorkflowDeleteService
  attr_accessor :workflow_id

  def initialize(workflow_id)
    self.workflow_id = workflow_id
  end

  def destroy
    begin
      retries ||= 0
      Workflow.find(workflow_id).destroy!
      EventService.new(nil).workflow_deleted(workflow_id)
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::Deadlocked, Exceptions::NegativeSequence # Failed to update sequence after deletion due to concurrent issue
      (retries += 1) < 3 ? retry : raise
    end
  end
end
