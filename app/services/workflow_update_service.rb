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

      if added_group_refs.any?
        ContextService.new(Insights::API::Common::Request.current.to_h.transform_keys(&:to_s)).as_org_admin do
          aps.add_resource_to_groups(workflow.id, added_group_refs)
        end
      end

      if removed_group_refs.any?
        ContextService.new(Insights::API::Common::Request.current.to_h.transform_keys(&:to_s)).as_org_admin do
          aps.remove_resource_from_groups(workflow.id, removed_group_refs)
        end
      end
    end

    workflow.update!(options)
  end
end
