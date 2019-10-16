class WorkflowFindService
  def find(tag_attrs)
    # TODO: need to retrieve tag name based on :object_id from remote app
    #  tag_attrs.merge(:tag_name => tag_name)
    workflow_ids = TagLink.where(tag_attrs.except(:object_id)).pluck(:workflow_id)

    Workflow.where(:id => workflow_ids)
  end
end
