class GetRemoteTags < RemoteTaggingService
  attr_reader :tags
  def initialize(options)
    super
    @tags = []
  end

  def process
    response = get_request(object_url)
    build_tags(response.body)
    self
  end

  def build_tags(body)
    JSON.parse(body).each do |tag|
      @tags << { :name => tag['name'], :namespace => tag['namespace'], :value => tag['value'] }
    end
  end
end
