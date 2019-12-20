require_relative 'mixins/tag_mixin'
class GetRemoteTags < RemoteTaggingService
  attr_reader :tags
  def initialize(options)
    super
    @tags = []
  end

  def process
    params = {}
    params['filter[name][eq]'] = TAG_NAME
    params['filter[namespace][eq]'] = TAG_NAMESPACE
    params['limit'] = QUERY_LIMIT
    response = get_request(object_url, params)
    @tags = JSON.parse(response.body)['data'].collect { |tag| tag['tag'] }
    self
  end
end
