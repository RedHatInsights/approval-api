class WorkflowFindService
  def find(tag_attrs_arr)
    tag_attrs_arr.collect do |tag_attrs|
      # TODO: need to retrieve tag name based on :object_id from remote app
      #  tag_attrs.merge(:tag_name => tag_name)
      tag_attrs.delete(:object_id)
      TagLink.where(tag_attrs).pluck(:workflow_id).first
    end
  end
end
