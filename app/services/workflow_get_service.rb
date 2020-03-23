require_relative 'mixins/group_validate_mixin'

class WorkflowGetService
  include GroupValidateMixin
  attr_accessor :workflow_id

  def initialize(workflow_id)
    self.workflow_id = workflow_id
  end

  def get
    Workflow.find(workflow_id).tap do |workflow|
      validate_and_update_approver_groups(workflow, false)
    end
  end
end
