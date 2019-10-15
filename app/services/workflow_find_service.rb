class WorkflowFindService
  def find(tag_attrs_arr)
    tag_attrs_arr.collect do |tag_attrs|
      tag_attrs.tap { |attrs| attrs.delete(:object_id) }
      TagLink.where(tag_attrs).pluck(:workflow_id).first
    end
  end
end
