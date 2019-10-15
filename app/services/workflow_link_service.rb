class WorkflowLinkService
  attr_accessor :workflow_id

  TAG_PREFIX = "/approval/workflows/".freeze

  def initialize(workflow_id)
    self.workflow_id = workflow_id
  end

  def link(tag_attrs)
    TagLink.find_or_create_by!(tag_link(tag_attrs))
    nil
  end

  private

  def tag_link(tag_attrs)
    tag_attrs.tap { |attrs| attrs.delete(:object_id) }.merge(:workflow_id => workflow_id, :tag_name => tag_name)
  end

  # TODO: create tag name based on workflow id
  def tag_name
    "#{TAG_PREFIX}#{workflow_id}"
  end
end
