class WorkflowUpdateService
  attr_accessor :workflow

  def initialize(workflow_id)
    self.workflow = Workflow.find(workflow_id)
  end

  def update(options)
    original_group_refs = workflow.group_refs
    current_group_refs = options[:group_refs]

    if current_group_refs
      removed_group_refs = original_group_refs - current_group_refs
      added_group_refs = current_group_refs - original_group_refs

      aps = AccessProcessService.new
      aps.add_resource_to_groups(workflow.id, added_group_refs) if added_group_refs.any?
      aps.remove_resource_from_groups(workflow.id, removed_group_refs) if removed_group_refs.any?
    end

    workflow.update!(options)
  end
end
