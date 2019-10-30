class WorkflowFindService
  # find workflows for a remote resource with app_name, object_type, and object_id
  def find(tag_attrs)
    # TODO: need to retrieve tag name based on :object_id from remote app
    #  tag_attrs.merge(:tag_name => tag_name)
    workflow_ids = TagLink.where(tag_attrs.except(:object_id)).pluck(:workflow_id)

    Workflow.where(:id => workflow_ids)
  end

  # find workflows from a collection of [app_name, object_type, [namespace, key, value]]
  def find_by_tag_resources(_tag_resources)
    []
  end
end
