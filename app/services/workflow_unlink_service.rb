require_relative 'mixins/tag_mixin'
class WorkflowUnlinkService
  include TagMixin
  attr_accessor :workflow_id

  def initialize(workflow_id = nil)
    self.workflow_id = workflow_id
  end

  def unlink(tag_attrs)
    DeleteRemoteTags.new(tag_attrs).process([approval_tag(workflow_id)])
  end
end
