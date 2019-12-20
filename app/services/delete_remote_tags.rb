class DeleteRemoteTags < RemoteTaggingService
  def process(tag)
    post_request(object_url, [tag])
    self
  end

  def object_url
    "#{service_url}/#{@object_type.underscore.pluralize}/#{@object_id}/untag"
  end
end
