require 'remote_tagging_service'
class WorkflowLinkService
  attr_accessor :workflow_id

  TAG_NAMESPACE = 'approval'.freeze
  TAG_NAME      = 'workflows'.freeze

  def initialize(workflow_id)
    self.workflow_id = workflow_id
  end

  def link(tag_attrs)
    TagLink.find_or_create_by!(tag_link(tag_attrs))
    RemoteTaggingService.new(tag_attrs).process('add', approval_tag)
    nil
  end

  private

  def tag_link(tag_attrs)
    tag_attrs.except(:object_id).merge(:workflow_id => workflow_id, :tag_name => fq_tag_name)
  end

  def fq_tag_name
    "/#{TAG_NAMESPACE}/#{TAG_NAME}=#{workflow_id}"
  end

  def approval_tag
    { :name      => TAG_NAME,
      :value     => workflow_id.to_s,
      :namespace => TAG_NAMESPACE }
  end
end
