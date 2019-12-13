require_relative 'mixins/tag_mixin'
class WorkflowLinkService
  include TagMixin
  attr_accessor :workflow_id

  def initialize(workflow_id)
    self.workflow_id = workflow_id
  end

  def link(tag_attrs)
    TagLink.find_or_create_by!(tag_link(tag_attrs))
    AddRemoteTags.new(tag_attrs).process(approval_tag(workflow_id))
    nil
  end

  private

  def tag_link(tag_attrs)
    tag_attrs.except(:object_id).merge(:workflow_id => workflow_id, :tag_name => fq_tag_name(workflow_id))
  end
end
