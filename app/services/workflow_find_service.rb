class WorkflowFindService
  # find workflows for a remote resource with app_name, object_type, and object_id
  def find(tag_attrs)
    tags = GetRemoteTags.new(tag_attrs).process.tags
    workflow_ids = TagLink.where(tag_attrs.except(:object_id)).where(:tag_name => tags).pluck(:workflow_id)

    Workflow.where(:id => workflow_ids)
  end

  # find workflows from a collection of [app_name, object_type, [tags]]
  def find_by_tag_resources(tag_resources)
    return [] if tag_resources.blank?

    query = nil
    tag_resources.each_with_index do |tr, i|
      tag_names = tr['tags'].collect { |tag| tag[:tag] }
      params = {:app_name => tr['app_name'], :object_type => tr['object_type'], :tag_name => tag_names}
      query =
        if i.zero?
          TagLink.where(params)
        else
          query.or(TagLink.where(params))
        end
    end
    Workflow.where(:id => query.select(:workflow_id).distinct)
  end
end
