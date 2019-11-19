require 'faraday'
class RemoteTaggingService
  VALID_200_CODES = [200, 201, 202, 204]
  def initialize(options)
    @app_name = options[:app_name]
    @object_type = options[:object_type]
    @object_id = options[:object_id]
  end

  def self.remotes
    [{ :app_name => 'topology', :object_type => 'ServiceInventory', :url => proc { topo_url } },
     { :app_name => 'topology', :object_type => 'Credential',       :url => proc { topo_url } },
     { :app_name => 'catalog',  :object_type => 'PortfolioItem',    :url => proc { catalog_url } },
     { :app_name => 'catalog',  :object_type => 'Portfolio',        :url => proc { catalog_url } },
     { :app_name => 'sources',  :object_type => 'Source',           :url => proc { sources_url } }]
  end

  private

  def self.topo_url
    url = ENV.fetch('TOPOLOGICAL_INVENTORY_URL') { raise 'TOPOLOGICAL_INVENTORY_URL is not set' }
    "#{url}/api/topological-inventory/v1.0"
  end
  private_class_method :topo_url

  def self.catalog_url
    url = ENV.fetch('CATALOG_URL') { raise 'CATALOG_URL is not set' }
    "#{url}/api/catalog/v1.0"
  end
  private_class_method :catalog_url

  def self.sources_url
    url = ENV.fetch('SOURCES_URL') { raise 'SOURCES_URL is not set' }
    "#{url}/api/sources/v1.0"
  end
  private_class_method :sources_url

  def object_url
    "#{service_url}/#{@object_type.underscore.pluralize}/#{@object_id}/tags"
  end

  def service_url
    match = self.class.remotes.detect { |item| item[:app_name] == @app_name && item[:object_type] == @object_type }
    raise "No url found for app #{@app_name} object #{@object_type}" unless match

    match[:url].call
  end

  def post_request(url, tag)
    con = Faraday.new
    response = con.post(url) do |session|
      session.headers['Content-Type'] = 'application/json'
      headers(session)
      session.body = tag.to_json
    end
    check_for_exceptions(response, "Error posting tags")
  end

  def get_request(url)
    con = Faraday.new
    response = con.get(url) do |session|
      headers(session)
    end
    check_for_exceptions(response, "Error getting tags")
    response
  end

  def check_for_exceptions(response, message_prefix)
    if response.status == 403
      raise Exceptions::NotAuthorizedError, response.reason_phrase
    else
      raise "#{message_prefix} #{response.reason_phrase}" unless VALID_200_CODES.include?(response.status)
    end
  end


  def headers(session)
    ManageIQ::API::Common::Request.current_forwardable.each do |k, v|
      session.headers[k] = v
    end
  end
end
