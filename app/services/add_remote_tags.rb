class AddRemoteTags < RemoteTaggingService
  def process(tag)
    post_request(object_url, tag)
    self
  end
end
