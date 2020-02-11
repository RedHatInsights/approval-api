require_relative 'mixins/tag_mixin'
require_relative 'mixins/group_validate_mixin'

class WorkflowLinkService
  include TagMixin
  include GroupValidateMixin
  attr_accessor :workflow_id

  def initialize(workflow_id)
    self.workflow_id = workflow_id
  end

  def link(tag_attrs)
    validate_approver_groups(Workflow.find(workflow_id).group_refs)

    TagLink.find_or_create_by!(tag_link(tag_attrs))
    AddRemoteTags.new(tag_attrs).process([approval_tag(workflow_id)])
    nil
  end

  private

  def tag_link(tag_attrs)
    tag_attrs.except(:object_id).merge(:workflow_id => workflow_id, :tag_name => fq_tag_name(workflow_id))
  end
end
