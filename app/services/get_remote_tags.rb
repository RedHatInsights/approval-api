class GetRemoteTags < RemoteTaggingService
  attr_reader :tags
  def initialize(options)
    super
    @tags = []
  end

  def process
    response = get_request(object_url)
    @tags = JSON.parse(response.body)['data'].collect {|tag| {:tag => tag['tag'] } }
    self
  end
end
