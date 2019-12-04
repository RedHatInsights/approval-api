class WorkflowDeleteService
  attr_accessor :workflow

  def initialize(workflow_id)
    self.workflow = Workflow.find(workflow_id)
  end

  def delete
    group_refs = workflow.group_refs

    if group_refs.any?
      aps = AccessProcessService.new

      ContextService.new(Insights::API::Common::Request.current.to_h.transform_keys(&:to_s)).as_org_admin do
        aps.remove_resource_from_groups(workflow.id, group_refs)
      end
    end

    # TODO: remove remote tags
    ##  tags = workflow.tag_links

    ##  if tags.any?
    ##    # DeleteRemoteTags.new(tags).process
    ##  end

    workflow.destroy!
  rescue ActiveRecord::RecordNotDestroyed
    workflow.errors[:base].include?(Workflow::MSG_PROTECTED_RECORD) ? raise(Exceptions::NotAuthorizedError, workflow.errors[:base]) : raise
  end
end
