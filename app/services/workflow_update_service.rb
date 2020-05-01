require_relative 'mixins/group_validate_mixin'

class WorkflowUpdateService
  include GroupValidateMixin
  attr_accessor :workflow

  def initialize(workflow_id)
    self.workflow = Workflow.find(workflow_id)
  end

  def update(options)
    if options[:group_refs]
      options[:group_refs] = validate_approver_groups(options[:group_refs])
    end

    begin
      retries ||=0
      Workflow.transaction do
        workflow.update!(options)
      end
    rescue ActiveRecord::RecordNotUnique # The auto generated sequence number may be found duplicated due to concurrent issue
      retry if (retries += 1) < 3
    end
  end
end
