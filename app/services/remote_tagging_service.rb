require 'faraday'
require_relative 'mixins/tag_mixin'
class RemoteTaggingService
  include TagMixin
  # TODO: Support proper pagination of tags from Faraday since
  # we are not using the generated client here.
  QUERY_LIMIT = 1000

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
    "#{url}/api/topological-inventory/v2.0"
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
    raise Exceptions::UserError.new("No url found for app #{@app_name} object #{@object_type}") unless match

    match[:url].call
  end

  def post_request(url, tags)
    call_remote_service do |con|
      con.post(url) do |session|
        session.headers['Content-Type'] = 'application/json'
        headers(session)
        session.body = tags.to_json
      end
    end
  end

  def get_request(url, params)
    call_remote_service do |con|
      con.get(url) do |session|
        headers(session)
        params.each { |k, v| session.params[k] = v }
      end
    end
  end

  def call_remote_service
    connection = Faraday.new
    yield(connection)
  rescue Faraday::TimeoutError => e
    raise Exceptions::TimedOutError, e.message
  rescue Faraday::ConnectionFailed => e
    raise Exceptions::NetworkError, e.message
  rescue Faraday::UnauthorizedError => e
    raise Exceptions::NotAuthorizedError, e.message
  rescue Faraday::Error => e
    raise Exceptions::TaggingError, e.message
  end

  def headers(session)
    Insights::API::Common::Request.current_forwardable.each do |k, v|
      session.headers[k] = v
    end
  end
end
