class WorkflowLinkService
  attr_accessor :workflow_id

  def initialize(workflow_id)
    self.workflow_id = workflow_id
  end

  def link(tag_attrs)
    TagLink.find_or_create_by!(tag_link(tag_attrs))
    nil
  end

  def unlink(tag_attrs)
    TagLink.find_by(tag_link(tag_attrs)).try(:destroy)
  end

  private

  def tag_link(tag_attrs)
    tag_attrs.merge(:workflow_id => workflow_id)
  end
end
