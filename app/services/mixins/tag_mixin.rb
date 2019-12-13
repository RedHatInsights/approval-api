module TagMixin
  TAG_NAMESPACE = 'approval'.freeze
  TAG_NAME      = 'workflows'.freeze

  def fq_tag_name(workflow_id)
    "/#{TAG_NAMESPACE}/#{TAG_NAME}=#{workflow_id}"
  end

  def approval_tag(workflow_id)
    { :tag => fq_tag_name(workflow_id) }
  end

  def approval_tag_filter
    "filter[namespace][eq]=#{TAG_NAMESPACE}&filter[name][eq]=/#{TAG_NAME}"
  end
end
