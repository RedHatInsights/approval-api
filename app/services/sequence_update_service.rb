class SequenceUpdateService
  attr_accessor :workflow_id

  def initialize(workflow_id)
    self.workflow_id = workflow_id
  end

  def move(delta)
    diff = case delta
           when 'top'
             -Float::INFINITY
           when 'bottom'
             Float::INFINITY
           else
             delta.to_i
           end

    Workflow.find(workflow_id).move_internal_sequence(diff)
  end
end
