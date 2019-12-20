class AddRemoteTags < RemoteTaggingService
  def process(tags)
    post_request(object_url, tags)
    self
  end

  def object_url
    "#{service_url}/#{@object_type.underscore.pluralize}/#{@object_id}/tag"
  end
end
