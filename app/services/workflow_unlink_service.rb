class WorkflowUnlinkService
  attr_accessor :workflow_id

  def initialize(workflow_id = nil)
    self.workflow_id = workflow_id
  end

  def unlink(tag_attrs)
    # TODO: find linked tag and remove it from resource object's tag list

    # Leave the tag link in the tag_links table!
  end
end
