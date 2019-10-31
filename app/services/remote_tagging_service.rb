require 'faraday'
class RemoteTaggingService

  def initialize(options)
    @app_name = options[:app_name]
    @object_type = options[:object_type]
    @object_id = options[:object_id]
  end

  def process(action, tag)
    post_request(action_url(action), tag) 
  end

  private

  def self.remotes
    [ {:app_name => 'topology', :object_type => 'ServiceInventory', :url => Proc.new {topo_url}},
      {:app_name => 'topology', :object_type => 'Credential',       :url => Proc.new {topo_url}},
      {:app_name => 'catalog',  :object_type => 'PortfolioItem',    :url => Proc.new {catalog_url}},
      {:app_name => 'catalog',  :object_type => 'Portfolio',        :url => Proc.new {catalog_url}},
      {:app_name => 'sources',  :object_type => 'Source',           :url => Proc.new {sources_url}} ]
  end

  def self.topo_url
    url = ENV.fetch('TOPOLOGICAL_INVENTORY_URL') { raise 'TOPOLOGICAL_INVENTORY_URL is not set'}
    "#{url}/api/topological-inventory/v1.0"
  end

  def self.catalog_url
    url = ENV.fetch('CATALOG_URL') { raise 'CATALOG_URL is not set'}
    "#{url}/api/catalog/v1.0"
  end

  def self.sources_url
    url = ENV.fetch('SOURCES_URL') { raise 'SOURCES_URL is not set'}
    "#{url}/api/sources/v1.0"
  end

  def action_url(action)
    url = service_url
    if action == 'add'
      "#{url}/#{@object_type.underscore.pluralize}/#{@object_id}/tags"
    else
      raise "Invalid action #{action}"
    end
  end

  def service_url
    match = self.class.remotes.detect { |item| item[:app_name] == @app_name && item[:object_type] == @object_type }
    raise "No url found for app #{@app_name} object #{@object_type}" unless match
    match[:url].call
  end

  def post_request(url, tag)
    con = Faraday.new
    res = con.post do |session|
      session.url url
      session.headers['Content-Type'] = 'application/json'
      ManageIQ::API::Common::Request.current_forwardable.each do |k, v|
        session.headers[k] = v
      end
      session.body = tag.to_json
    end
    raise "Error posting tags #{res.reason_phrase}" unless res.status == 200
  end
end
